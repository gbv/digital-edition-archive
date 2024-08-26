package de.gbv.dea;

import static de.gbv.dea.DEAUtils.TEI_NS;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jdom2.Attribute;
import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.JDOMException;
import org.jdom2.input.SAXBuilder;
import org.mycore.access.MCRAccessException;
import org.mycore.common.MCRConstants;
import org.mycore.common.MCRException;
import org.mycore.datamodel.metadata.MCRMetaClassification;
import org.mycore.datamodel.metadata.MCRMetadataManager;
import org.mycore.datamodel.metadata.MCRObject;
import org.mycore.datamodel.metadata.MCRObjectID;
import org.mycore.datamodel.metadata.validator.MCREditorOutValidator;
import org.mycore.datamodel.niofs.MCRPath;
import org.mycore.frontend.MCRFrontendUtil;
import org.mycore.services.i18n.MCRTranslation;
import org.mycore.webtools.upload.MCRDefaultUploadHandler;
import org.mycore.webtools.upload.MCRFileUploadBucket;
import org.mycore.webtools.upload.MCRUploadHandler;
import org.mycore.webtools.upload.exception.MCRInvalidFileException;
import org.mycore.webtools.upload.exception.MCRInvalidUploadParameterException;
import org.mycore.webtools.upload.exception.MCRMissingParameterException;
import org.mycore.webtools.upload.exception.MCRUploadException;
import org.mycore.webtools.upload.exception.MCRUploadForbiddenException;
import org.mycore.webtools.upload.exception.MCRUploadServerException;

import de.gbv.dea.shelfmark.ShelfMarkMappingManager;

public class DEATEIUploadHandler implements MCRUploadHandler {

    public static final String FILE_NAME_PATTERN = "(?<number>[0-9]{6}).*\\.xml";
    private static final Logger LOGGER = LogManager.getLogger();

    public MCRObjectID traverse(Path fileOrDirectory, String project, List<MCRMetaClassification> classifications, MCRObjectID parent)
        throws MCRUploadServerException, MCRInvalidFileException, IOException {
        Objects.requireNonNull(project, () -> MCRTranslation.translate("fileupload.tei.project.missing"));
        Objects.requireNonNull(parent, () -> MCRTranslation.translate("fileupload.tei.parent.missing"));
        try {
            if (Files.isDirectory(fileOrDirectory)) {
                // file is a directory and should be named like 000001, 000002, 000003, ...
                // and should contain a file named 000001*.xml
                // and should contain a directory name images
                Path teiFile = findTEIFile(fileOrDirectory);
                Document parsedTEI = parseTEI(teiFile);
                String shelfmark = getShelfmarkFromTEIFile(parsedTEI).orElseThrow(
                    () -> new MCRInvalidFileException(teiFile.toString(), "fileupload.tei.file.missingShelfmark", true,
                        teiFile.toString()));

                MCRObjectID objectID = ShelfMarkMappingManager.getMappedMycoreID(shelfmark, project)
                        .map(MCRObjectID::getInstance)
                        .orElseGet(()-> MCRMetadataManager.getMCRObjectIDGenerator().getNextFreeId(project,"tei"));


                Document tei = importOrUpdateTEIMyCoReObject(teiFile, objectID, classifications, parent);

                Path imagesDirectory = findImagesDirectory(fileOrDirectory, objectID);
                MCRObjectID contentDerivate = DEAUtils.createDerivateIfNotExists(objectID,
                    DEAUtils.DERIVATE_TYPES_CONTENT);

                LOGGER.info("Processing object " + objectID);
                if (imagesDirectory != null) {
                    DEAUtils.importImages(imagesDirectory, contentDerivate);
                } else {
                    LOGGER.warn("No images directory found for object " + objectID);
                }

                DEAUtils.splitTEIFileToDerivate(tei, objectID, MCRPath.getPath(contentDerivate.toString(), "/"));

                return objectID;
            } else if (Files.isRegularFile(fileOrDirectory)) {
                // file is a file and should be named like 000001*.xml
                if (!fileOrDirectory.toString().endsWith(".xml")) {
                    throw new MCRInvalidFileException(fileOrDirectory.toString(), "Not a TEI file.");
                } else if (!fileOrDirectory.getFileName().toString().matches(FILE_NAME_PATTERN)) {
                    throw new MCRInvalidFileException(fileOrDirectory.toString(),
                        "File name does not match pattern. [0-9]{6}.*\\.xml");
                }
                Document parsedTEI = parseTEI(fileOrDirectory);
                String shelfmark = getShelfmarkFromTEIFile(parsedTEI).orElseThrow(
                        () -> new MCRInvalidFileException(fileOrDirectory.toString(), "fileupload.tei.file.missingShelfmark", true,
                                fileOrDirectory.toString()));
                MCRObjectID objectID = ShelfMarkMappingManager.getMappedMycoreID(shelfmark, project)
                        .map(MCRObjectID::getInstance)
                        .orElseGet(()-> MCRMetadataManager.getMCRObjectIDGenerator().getNextFreeId(project,"tei"));
                importOrUpdateTEIMyCoReObject(fileOrDirectory, objectID, classifications, parent);
                return objectID;
            }
        } catch (Throwable t) {
            LOGGER.error("Error while processing " + fileOrDirectory.toString(), t);
            throw t;
        }
        return null;
    }

    public Optional<String> getShelfmarkFromTEIFile(Document tei) {
        Attribute idAttr = tei.getRootElement().getChild("teiHeader", TEI_NS).getChild("fileDesc", TEI_NS)
            .getAttribute("id", MCRConstants.XML_NAMESPACE);
        if (idAttr != null) {
            return Optional.of(idAttr.getValue());
        }
        return Optional.empty();
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

    public Document importOrUpdateTEIMyCoReObject(Path teiFile, MCRObjectID objectID,
        List<MCRMetaClassification> classifications, MCRObjectID parent) throws IOException,
        MCRInvalidFileException {
        boolean exists = MCRMetadataManager.exists(objectID);
        Document teiDocument = parseTEI(teiFile);

        Document documentWithHeaderOnly = new Document();
        documentWithHeaderOnly.setRootElement(teiDocument.getRootElement().getChild("teiHeader", TEI_NS).clone());

        Element teiHeader = documentWithHeaderOnly.getRootElement();

        MCRObject object;
        if (exists) {
            object = MCRMetadataManager.retrieveMCRObject(objectID);
            DEAUtils.setTEI(object, teiHeader);
        } else {
            object = new MCRObject();
            object.setId(objectID);
            object.setSchema("datamodel-tei.xsd");
            object.setImportMode(true);
            DEAUtils.setTEI(object, teiHeader);
        }
        object.getService().setState("published");
        object.getStructure().setParent(parent);

        try {
            MCREditorOutValidator ev = new MCREditorOutValidator(object.createXML(), objectID);
            ev.generateValidMyCoReObject();
        } catch (RuntimeException | JDOMException e) {
            String fileName = teiFile.getFileName().toString();
            throw new MCRInvalidFileException(fileName, "fileupload.tei.file.invalid", true, fileName, e.getMessage());
        }

        try {
            MCRMetadataManager.update(object);
        } catch (MCRAccessException e) {
            throw new MCRException("Error while updating object " + objectID, e);
        }

        DEAUtils.storeFileInOriginalDerivate(teiFile, objectID);

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

    @Override
    public String begin(Map<String, List<String>> parameters) throws MCRUploadForbiddenException,
        MCRUploadServerException, MCRMissingParameterException, MCRInvalidUploadParameterException {
        String parentStr;
        if (parameters.containsKey("parent")) {
            parentStr = parameters.get("parent").get(0);
            if (parentStr.isEmpty()) {
                throw new MCRInvalidUploadParameterException("parent", "", "empty");
            }
        } else {
            throw new MCRMissingParameterException("parent");
        }
        MCRObjectID parent = MCRObjectID.getInstance(parentStr);

        try {
            MCRMetadataManager.checkCreatePrivilege(
                MCRObjectID.getInstance(MCRObjectID.formatID(parent.getProjectId(), "tei", 0)));
        } catch (MCRAccessException e) {
            throw new MCRUploadForbiddenException("mcr.upload.forbidden");
        }

        return UUID.randomUUID().toString();
    }

    @Override
    public URI commit(MCRFileUploadBucket bucket) throws MCRUploadException {
        Map<String, List<String>> parameters = bucket.getParameters();
        MCRObjectID parent = getParent(bucket.getParameters());
        List<MCRMetaClassification> classifications = MCRDefaultUploadHandler.getClassifications(parameters);
        Path rootPath = bucket.getRoot();
        try (Stream<Path> files = Files.list(rootPath)) {
            return new URI(MCRFrontendUtil.getBaseURL() + "receive/" + files
                .map((f) -> {
                    try {
                        return this.traverse(f, parent.getProjectId(), classifications, parent);
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
            if (e.getCause() instanceof MCRUploadException muse) {
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

    private MCRObjectID getParent(Map<String, List<String>> parameters) throws MCRInvalidUploadParameterException {
        String parent = parameters.get("parent").get(0);
        if (parent.isEmpty()) {
            throw new MCRInvalidUploadParameterException("parent", "", "empty");
        }
        if(MCRObjectID.isValid(parent)) {
            return MCRObjectID.getInstance(parent);
        } else {
            throw new MCRInvalidUploadParameterException("parent", parent, "invalid");
        }
    }

    @Override
    public void validateFileMetadata(String name, long size)
        throws MCRInvalidFileException {
        new MCRDefaultUploadHandler().validateFileMetadata(name, size);
    }

}
