package de.gbv.dea;

import org.jdom2.Content;
import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.Namespace;
import org.jdom2.filter.Filters;
import org.jdom2.output.Format;
import org.jdom2.output.XMLOutputter;
import org.jdom2.xpath.XPathFactory;
import org.mycore.access.MCRAccessException;
import org.mycore.common.MCRException;
import org.mycore.datamodel.metadata.MCRDerivate;
import org.mycore.datamodel.metadata.MCRMetaElement;
import org.mycore.datamodel.metadata.MCRMetaXML;
import org.mycore.datamodel.metadata.MCRMetadataManager;
import org.mycore.datamodel.metadata.MCRObject;
import org.mycore.datamodel.metadata.MCRObjectID;
import org.mycore.datamodel.metadata.MCRObjectMetadata;
import org.mycore.datamodel.niofs.MCRPath;
import org.mycore.datamodel.niofs.utils.MCRRecursiveDeleter;
import org.mycore.datamodel.niofs.utils.MCRTreeCopier;
import org.mycore.frontend.fileupload.MCRUploadHelper;
import org.mycore.mets.model.Mets;
import org.mycore.webtools.upload.MCRDefaultUploadHandler;
import org.mycore.webtools.upload.exception.MCRUploadServerException;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.List;

public class DEAUtils {

    public static final Namespace TEI_NS = Namespace.getNamespace("tei", "http://www.tei-c.org/ns/1.0");
    public static final String DEF_TEI_CONTAINER = "def.teiContainer";
    public static final String TEI_CONTAINER = "teiContainer";
    public static final String DERIVATE_TYPES_CLASS = "derivate_types";
    public static final String DERIVATE_TYPES_CONTENT = "content";
    public static final String DERIVATE_TYPES_ORIGINAL = "original";

    public static Element getTEI(MCRObject object) {
        try {
            MCRMetaXML mx = (MCRMetaXML) (object.getMetadata().getMetadataElement(DEF_TEI_CONTAINER).getElement(0));
            for (Content content : mx.getContent()) {
                if (content instanceof Element element) {
                    return element;
                }
            }
        } catch (NullPointerException | IndexOutOfBoundsException e) {
            //do nothing
        }
        return null;
    }

    public static void setTEI(MCRObject object,Element tei) {
        MCRObjectMetadata om = object.getMetadata();
        if (om.getMetadataElement(DEF_TEI_CONTAINER) != null) {
            om.removeMetadataElement(DEF_TEI_CONTAINER);
        }
        MCRMetaXML teiContainer = new MCRMetaXML(TEI_CONTAINER, null, 0);
        List<MCRMetaXML> list = List.of(teiContainer);
        MCRMetaElement defTeiContainer = new MCRMetaElement(MCRMetaXML.class, DEF_TEI_CONTAINER, false, true, list);
        om.setMetadataElement(defTeiContainer);
        teiContainer.addContent(tei);
    }

    public static MCRObjectID createDerivateIfNotExists(MCRObjectID objectID, String contentType) {
        if (!MCRMetadataManager.exists(objectID)) {
            return null;
        }
        MCRObject object = MCRMetadataManager.retrieveMCRObject(objectID);

        String ctName = DERIVATE_TYPES_CLASS + ":" + contentType;
        var derivates = object.getStructure().getDerivates().stream()
            .filter(link -> link.getClassifications().stream()
                .anyMatch(classification -> classification.toString().equals(ctName)))
            .toList();

        if (derivates.size() == 1) {
            return derivates.get(0).getXLinkHrefID();
        } else if (derivates.size() > 1) {
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

    public static void importImages(Path imagesDirectory, MCRObjectID derivateId) throws MCRUploadServerException {
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
    public static void storeFileInOriginalDerivate(Path teiFile, MCRObjectID objectID) throws IOException {
        // create or use existing derivate to store the original TEI file
        MCRObjectID originalDerivate = DEAUtils.createDerivateIfNotExists(objectID, DERIVATE_TYPES_ORIGINAL);
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

    /**
     * Returns the first title element of the given TEI file.
     *
     * @param tei the TEI file
     * @return the title of the TEI file
     */
    public static String getTitle(Element tei) {
        XPathFactory xPathFactory = XPathFactory.instance();
        return xPathFactory.compile("(.|tei:teiHeader)/tei:fileDesc/tei:titleStmt/tei:title[1]",
                        Filters.element(),
                        null,
                        DEAUtils.TEI_NS)
                .evaluateFirst(tei)
                .getTextNormalize();
    }

    /**
     * Splits the given TEI file into several files and stores them in the derivate of the given object.
     * @param tei the TEI file to split
     * @param objectID the object id of the derivate to which the MCRPath belongs
     * @param root the root path of the derivate
     */
    public static void splitTEIFileToDerivate(Document tei, MCRObjectID objectID, MCRPath root) throws MCRUploadServerException {
        Path transcriptionFolderPath = root.resolve("tei/").resolve("transcription");
        if (Files.exists(transcriptionFolderPath)) {
            // files already exist, delete them and recreate the folder
            try {
                Files.walkFileTree(transcriptionFolderPath, MCRRecursiveDeleter.instance());
            } catch (IOException e) {
                throw new MCRException(e);
            }
        }
        try {
            Files.createDirectories(transcriptionFolderPath);
        } catch (IOException e) {
            throw new MCRException(e);
        }

        DEATEISplitter splitter = new DEATEISplitter(new DEATEISplitter.TeiFile(objectID.toString(), tei, "0"));
        List<DEATEISplitter.TeiFile> split = splitter.split();
        split.stream()
            .filter(file -> file.name() != null)
            .forEach(teiFile -> {
                String name = teiFile.name();
                try (OutputStream os = Files.newOutputStream(transcriptionFolderPath.resolve(removeFileEnding(name) + ".xml"))) {
                    XMLOutputter xmlOutputter = new XMLOutputter(Format.getRawFormat());
                    xmlOutputter.output(teiFile.doc(), os);
                } catch (IOException e) {
                    throw new MCRException(e);
                }
            });

        DEATEIMetsGenerator metsGenerator = new DEATEIMetsGenerator(root, split, DEAUtils.getTitle(tei.getRootElement()));
        try {
            metsGenerator.generate();
        } catch (IOException e) {
            throw new MCRUploadServerException("mcr.upload.import.failed", e);
        }
        Mets mets = metsGenerator.getMets();
        Document document = mets.asDocument();
        try (OutputStream os = Files.newOutputStream(root.resolve("mets.xml"), StandardOpenOption.TRUNCATE_EXISTING,
                StandardOpenOption.CREATE)) {
            XMLOutputter xmlOutputter = new XMLOutputter(Format.getPrettyFormat());
            xmlOutputter.output(document, os);
        } catch (IOException e) {
            throw new MCRException(e);
        }
    }

    public static String removeFileEnding(String name) {
        return name.substring(0, name.lastIndexOf('.'));
    }


}
