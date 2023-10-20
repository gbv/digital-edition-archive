package de.gbv.dea;

import static de.gbv.dea.DEAUtils.TEI_NS;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.JDOMException;
import org.jdom2.input.SAXBuilder;
import org.jdom2.output.Format;
import org.jdom2.output.XMLOutputter;
import org.mycore.access.MCRAccessException;
import org.mycore.common.MCRException;
import org.mycore.datamodel.metadata.*;
import org.mycore.datamodel.niofs.MCRPath;
import org.mycore.datamodel.niofs.utils.MCRRecursiveDeleter;
import org.mycore.datamodel.niofs.utils.MCRTreeCopier;
import org.mycore.frontend.MCRFrontendUtil;
import org.mycore.frontend.fileupload.MCRUploadHelper;
import org.mycore.webtools.upload.MCRDefaultUploadHandler;
import org.mycore.webtools.upload.MCRFileUploadBucket;
import org.mycore.webtools.upload.MCRUploadHandler;
import org.mycore.webtools.upload.exception.MCRInvalidFileException;
import org.mycore.webtools.upload.exception.MCRInvalidUploadParameterException;
import org.mycore.webtools.upload.exception.MCRMissingParameterException;
import org.mycore.webtools.upload.exception.MCRUploadForbiddenException;
import org.mycore.webtools.upload.exception.MCRUploadServerException;

public class DEATEIUploadHandler implements MCRUploadHandler {

    private static final Logger LOGGER = LogManager.getLogger();
    public static final String FILE_NAME_PATTERN = "(?<number>[0-9]{6}).*\\.xml";

    private static final String DERIVATE_TYPES_CLASS = "derivate_types";
    private static final String DERIVATE_TYPES_CONTENT = "content";
    private static final String DERIVATE_TYPES_ORIGINAL = "original";

    public MCRObjectID traverse(Path fileOrDirectory, String project, List<MCRMetaClassification> classifications)
            throws MCRUploadServerException, MCRInvalidFileException, IOException {
        try {
            if (Files.isDirectory(fileOrDirectory)) {
                // file is a directory and should be named like 000001, 000002, 000003, ...
                // and should contain a file named 000001*.xml
                // and should contain a directory name images
                MCRObjectID objectID = getObjectIDFromDirectory(fileOrDirectory, project);
                Path teiFile = findTEIFile(fileOrDirectory);
                Document tei = importOrUpdateTEIMyCoReObject(teiFile, objectID, classifications);

                Path imagesDirectory = findImagesDirectory(fileOrDirectory, objectID);
                MCRObjectID contentDerivate = createDerivateIfNotExists(objectID, DERIVATE_TYPES_CONTENT);

                LOGGER.info("Processing object " + objectID);
                if (imagesDirectory != null) {
                    importImages(imagesDirectory, contentDerivate);
                } else {
                    LOGGER.warn("No images directory found for object " + objectID);
                }

                splitTEIFileToDerivate(tei, objectID, MCRPath.getPath(contentDerivate.toString(), "/"));

                return objectID;
            } else if (Files.isRegularFile(fileOrDirectory)) {
                // file is a file and should be named like 000001*.xml
                if (!fileOrDirectory.toString().endsWith(".xml")) {
                    throw new MCRInvalidFileException(fileOrDirectory.toString(), "Not a TEI file.");
                } else if (!fileOrDirectory.getFileName().toString().matches(FILE_NAME_PATTERN)) {
                    throw new MCRInvalidFileException(fileOrDirectory.toString(),
                        "File name does not match pattern. [0-9]{6}.*\\.xml");
                }

                MCRObjectID objectID = getObjectIDFromFile(fileOrDirectory, project);
                importOrUpdateTEIMyCoReObject(fileOrDirectory, objectID, classifications);
                return objectID;
            }
        } catch (Throwable t) {
            LOGGER.error("Error while processing " + fileOrDirectory.toString(), t);
            throw t;
        }
        return null;
    }

    private void importImages(Path imagesDirectory, MCRObjectID derivateId) throws MCRUploadServerException {
        MCRPath root = MCRPath.getPath(derivateId.toString(), "/");
        try {
            Files.createDirectories(root);
        } catch (IOException e) {
            throw new MCRUploadServerException("mcr.upload.import.failed", e);
        }
        final MCRTreeCopier copier;
        try {
            copier = new MCRTreeCopier(imagesDirectory, root, false, true);
        } catch (NoSuchFileException e) {
            throw new MCRException(e);
        }

        try {
            Files.walkFileTree(imagesDirectory, copier);
        } catch (IOException e) {
            throw new MCRUploadServerException("mcr.upload.import.failed", e);
        }

        MCRDerivate theDerivate = MCRMetadataManager.retrieveMCRDerivate(derivateId);

        String mainDoc = theDerivate.getDerivate().getInternals().getMainDoc();
        if (mainDoc == null || mainDoc.isEmpty()) {
            MCRDefaultUploadHandler.setDefaultMainFile(theDerivate);
        }
    }

    private static MCRObjectID createDerivateIfNotExists(MCRObjectID objectID, String contentType) {
        if (!MCRMetadataManager.exists(objectID)) {
            return null;
        }
        MCRObject object = MCRMetadataManager.retrieveMCRObject(objectID);

        String ctName = DERIVATE_TYPES_CLASS + ":" + contentType;
        var derivates = object.getStructure().getDerivates().stream()
                .filter(link -> link.getClassifications().stream()
                .anyMatch(classification -> classification.toString().equals(ctName)))
                .toList();

        if(derivates.size() == 1) {
            return derivates.get(0).getXLinkHrefID();
        } else if(derivates.size() > 1) {
            throw new MCRException("Object " + objectID + " has more than one derivate of type " + contentType);
        } else {
            try {
                var contentTypeClass = MCRUploadHelper.getClassifications(ctName);
                return MCRUploadHelper.createDerivate(objectID, contentTypeClass).getId();
            } catch (MCRAccessException e) {
                throw new MCRException("Error while creating derivate for object " + objectID, e);
            }
        }
    }

    private Path findImagesDirectory(Path fileOrDirectory, MCRObjectID objectID) {
        Path images = fileOrDirectory.resolve("images");
        if (Files.exists(images)) {
            return images;
        } else {
            return null;
        }
    }

    public Path findTEIFile(Path directory) {
        try {
            return Files.find(directory, 1,
                    (path, basicFileAttributes) -> path.getFileName().toString().matches(FILE_NAME_PATTERN))
                .findFirst().orElse(null);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }


    public MCRObjectID getObjectIDFromDirectory(Path path, String project) throws IllegalArgumentException {
        // path is a directory and should be named like 000001
        if (!Files.isDirectory(path)) {
            throw new IllegalArgumentException("Path is not a directory.");
        }

        String file = path.getFileName().toString();
        if (!file.matches("[0-9]{6}")) {
            throw new IllegalArgumentException("Name " + file + " does not consist of 6 digits.");

        }

        int number = Integer.parseInt(file);
        String formattedIDString = MCRObjectID.formatID(project + "_tei_", number);
        return MCRObjectID.getInstance(formattedIDString);

    }

    public MCRObjectID getObjectIDFromFile(Path file, String project) throws IllegalArgumentException {
        if (!Files.isRegularFile(file)) {
            throw new IllegalArgumentException("File is not a regular file.");
        }

        String fileName = file.getFileName().toString();
        Pattern pattern = Pattern.compile(FILE_NAME_PATTERN);
        Matcher matcher = pattern.matcher(fileName);
        String numberStr;

        if (matcher.find()) {
            numberStr = matcher.group("number");
        } else {
            throw new IllegalArgumentException("File name does not match pattern. [0-9]{6}.*\\.xml");
        }

        int number = Integer.parseInt(numberStr);
        String formattedIDString = MCRObjectID.formatID(project + "_tei_", number);
        return MCRObjectID.getInstance(formattedIDString);
    }

    public Document importOrUpdateTEIMyCoReObject(Path teiFile, MCRObjectID objectID,
        List<MCRMetaClassification> classifications) throws IOException {
        boolean exists = MCRMetadataManager.exists(objectID);
        Document teiDocument = parseTEI(teiFile);

        Document documentWithHeaderOnly = teiDocument.clone();
        Element rootElement = documentWithHeaderOnly.getRootElement();
        Element teiHeader = rootElement.getChild("teiHeader", TEI_NS).detach();
        rootElement.removeContent();
        rootElement.addContent(teiHeader);

        MCRObject object;
        if (exists) {
            object = MCRMetadataManager.retrieveMCRObject(objectID);
            DEAUtils.setTEI(object, rootElement);
        } else {
            object = new MCRObject();
            object.setId(objectID);
            object.setSchema("datamodel-tei.xsd");
            object.setImportMode(true);
            DEAUtils.setTEI(object, rootElement);
        }
        object.getService().setState("published");

        try {
            MCRMetadataManager.update(object);
        } catch (MCRAccessException e) {
            throw new MCRException("Error while updating object " + objectID, e);
        }

        storeFileInOriginalDerivate(teiFile, objectID);

        return teiDocument;
    }

    /**
     * Due to the fact that the original tei file is seperated in to several files, the original tei file is stored in
     * the original derivate.
     *
     * This method stores the given TEI file in the original derivate of the given object. If the derivate does not
     * exist, it will be created. If it exists, all files will be deleted. The given file will be stored as main
     * document.
     * @param teiFile the TEI file to store
     * @param objectID the object id of the object to store the TEI file in
     * @throws IOException if an I/O error occurs
     */
    private static void storeFileInOriginalDerivate(Path teiFile, MCRObjectID objectID) throws IOException {
        // create or use existing derivate to store the original TEI file
        MCRObjectID originalDerivate = createDerivateIfNotExists(objectID, DERIVATE_TYPES_ORIGINAL);
        Path fileName = teiFile.getFileName();
        MCRPath originalDerivatePath = MCRPath.getPath(originalDerivate.toString(), "/");
        Files.walkFileTree(originalDerivatePath, MCRRecursiveDeleter.instance());
        Path fn = originalDerivatePath.resolve(fileName.toString());
        Files.copy(teiFile, fn);
        MCRDerivate mcrDerivate = MCRMetadataManager.retrieveMCRDerivate(originalDerivate);
        mcrDerivate.getDerivate().getInternals().setMainDoc(fileName.toString());
        try {
            MCRMetadataManager.update(mcrDerivate);
        } catch (MCRAccessException e) {
            throw new MCRException("Error while updating derivate " + originalDerivate, e);
        }
    }

    public Document parseTEI(Path teiFile) {
        SAXBuilder saxBuilder = new SAXBuilder();
        try (InputStream is = Files.newInputStream(teiFile)) {
            return saxBuilder.build(is);
        } catch (IOException | JDOMException e) {
            throw new RuntimeException(e);
        }
    }

    public static void splitTEIFileToDerivate(Document tei, MCRObjectID objectID, MCRPath root) {
        Path transcriptionFolderPath = root.resolve("tei/").resolve("transcription");
        if (!Files.exists(transcriptionFolderPath)) {
            try {
                Files.createDirectories(transcriptionFolderPath);
            } catch (IOException e) {
                throw new MCRException(e);
            }
        }
        DEATEISplitter splitter = new DEATEISplitter(new DEATEISplitter.TeiFile(objectID.toString(), tei));
        List<DEATEISplitter.TeiFile> split = splitter.split();
        split.stream()
            .filter(file -> file.name() != null)
            .forEach(teiFile -> {
                String name = teiFile.name();

                try (OutputStream os = Files.newOutputStream(transcriptionFolderPath.resolve(name + ".xml"))) {
                    XMLOutputter xmlOutputter = new XMLOutputter(Format.getRawFormat());
                    xmlOutputter.output(teiFile.doc(), os);
                } catch (IOException e) {
                    throw new MCRException(e);
                }

            });
    }

    @Override
    public String begin(Map<String, List<String>> parameters) throws MCRUploadForbiddenException,
        MCRUploadServerException, MCRMissingParameterException, MCRInvalidUploadParameterException {
        String project;
        if (parameters.containsKey("project")) {
            project = parameters.get("project").get(0);
            if (project.isEmpty()) {
                throw new MCRInvalidUploadParameterException("project", "", "empty");
            }
        } else {
            throw new MCRMissingParameterException("project");
        }

        try {
            MCRMetadataManager.checkCreatePrivilege(
                    MCRObjectID.getInstance(MCRObjectID.formatID(project, "tei", 0)));
        } catch (MCRAccessException e) {
            throw new MCRUploadForbiddenException("mcr.upload.forbidden");
        }

        return UUID.randomUUID().toString();
    }

    @Override
    public URI commit(MCRFileUploadBucket bucket) throws MCRUploadServerException {
        Map<String, List<String>> parameters = bucket.getParameters();
        String project = getProject(bucket.getParameters());
        List<MCRMetaClassification> classifications = MCRDefaultUploadHandler.getClassifications(parameters);
        Path rootPath = bucket.getRoot();
        try (Stream<Path> files = Files.list(rootPath)) {
            return new URI(MCRFrontendUtil.getBaseURL() + "receive/" + files
                .map((f) -> {
                    try {
                        return this.traverse(f, project, classifications);
                    } catch (MCRUploadServerException | MCRInvalidFileException | IOException e) {
                        throw new MCRException(e);
                    }
                })
                .filter(Objects::nonNull)
                .collect(Collectors.toSet())
                .stream()
                .findFirst()
                .get());
        } catch (MCRException e) {
            if (e.getCause() instanceof MCRUploadServerException muse) {
                throw muse;
            } else {
                throw e;
            }
        } catch (IOException e) {
            throw new RuntimeException("Error while commiting upload (traversing files).", e);
        } catch (URISyntaxException e) {
            throw new RuntimeException("Error while creating URI.", e);
        }
    }

    private String getProject(Map<String, List<String>> parameters) {
        return parameters.get("project").get(0);
    }

    @Override
    public void validateFileMetadata(String name, long size)
        throws MCRInvalidFileException {
        new MCRDefaultUploadHandler().validateFileMetadata(name, size);
    }

}
