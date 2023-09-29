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
import java.nio.file.attribute.BasicFileAttributes;
import java.util.*;
import java.util.function.BiPredicate;
import java.util.stream.Collectors;
import java.util.stream.Stream;

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

    public MCRObjectID traverse(Path fileOrDirectory, String project, List<MCRMetaClassification> classifications)
        throws MCRUploadServerException {
        if (Files.isDirectory(fileOrDirectory)) {
            // file is a directory and should be named like 000001, 000002, 000003, ...
            // and should contain a file named 000001*.xml
            // and should contain a directory name images
            MCRObjectID objectID = getObjectIDFromDirectory(fileOrDirectory, project);
            Path teiFile = findTEIFile(fileOrDirectory);
            Document tei = importOrUpdateTEIMyCoReObject(teiFile, objectID, classifications);

            Path imagesDirectory = findImagesDirectory(fileOrDirectory, objectID);
            MCRObjectID derivateId = createDerivateIfNotExists(objectID);
            if (!(imagesDirectory == null)) {
                throw new MCRUploadServerException("Object does not exist!");
            }
            importImages(imagesDirectory, derivateId);
            saveTEIFileInDerivate(tei, objectID, MCRPath.getPath(derivateId.toString(), "/"));

            return objectID;
        } else if (Files.isRegularFile(fileOrDirectory)) {
            // file is a file and should be named like 000001*.xml
        } else {
            // file is neither a directory nor a file
        }
        return null;
    }

    private void importImages(Path imagesDirectory, MCRObjectID derivateId) throws MCRUploadServerException {
        MCRPath root = MCRPath.getPath(derivateId.toString(), "/");
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

    private static MCRObjectID createDerivateIfNotExists(MCRObjectID objectID) {
        MCRObjectID derivateId;
        if (!MCRMetadataManager.exists(objectID)) {
            return null;
        }
        MCRObject object = MCRMetadataManager.retrieveMCRObject(objectID);
        if (object.getStructure().getDerivates().isEmpty()) {
            try {
                derivateId = MCRUploadHelper.createDerivate(objectID, Collections.emptyList()).getId();
            } catch (MCRAccessException e) {
                throw new MCRException("Error while creating derivate for object " + objectID, e);
            }
        } else {
            derivateId = object.getStructure().getDerivates().get(0).getXLinkHrefID();
        }
        return derivateId;
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
            return Files
                .find(directory, 1,
                    (path, basicFileAttributes) -> path.getFileName().toString().matches("[0-9]{6}.*\\.xml"))
                .findFirst().orElse(null);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    public MCRObjectID getObjectIDFromDirectory(Path path, String project) throws IllegalArgumentException {
        // path is a directory and should be named like 000001
        if (Files.isDirectory(path)) {
            String file = path.getFileName().toString();
            if (file.matches("[0-9]{6}")) {
                int number = Integer.parseInt(file);
                String formattedIDString = MCRObjectID.formatID(project + "_tei_", number);
                MCRObjectID id = MCRObjectID.getInstance(formattedIDString);
                return id;
            } else {
                throw new IllegalArgumentException("Name does not consist of 6 digits.");
            }
        } else {
            throw new IllegalArgumentException("Path is not a directory.");
        }
    }

    public Document importOrUpdateTEIMyCoReObject(Path teiFile, MCRObjectID objectID,
        List<MCRMetaClassification> classifications) {
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
        return teiDocument;
    }

    public Document parseTEI(Path teiFile) {
        SAXBuilder saxBuilder = new SAXBuilder();
        try (InputStream is = Files.newInputStream(teiFile)) {
            return saxBuilder.build(is);
        } catch (IOException | JDOMException e) {
            throw new RuntimeException(e);
        }
    }

    public static void saveTEIFileInDerivate(Document tei, MCRObjectID objectID, MCRPath root) {
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
                    } catch (MCRUploadServerException e) {
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
