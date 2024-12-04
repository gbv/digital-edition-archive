package de.gbv.dea;

import de.gbv.dea.shelfmark.ShelfMarkMappingManager;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.JDOMException;
import org.jdom2.Namespace;
import org.jdom2.filter.Filters;
import org.jdom2.input.SAXBuilder;
import org.jdom2.xpath.XPathExpression;
import org.jdom2.xpath.XPathFactory;
import org.mycore.access.MCRAccessException;
import org.mycore.common.MCRException;
import org.mycore.datamodel.metadata.MCRMetadataManager;
import org.mycore.datamodel.metadata.MCRObject;
import org.mycore.datamodel.metadata.MCRObjectID;
import org.mycore.datamodel.metadata.validator.MCREditorOutValidator;
import org.mycore.frontend.cli.annotation.MCRCommand;
import org.mycore.frontend.cli.annotation.MCRCommandGroup;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.List;

import static de.gbv.dea.DEAUtils.TEI_NS;

@MCRCommandGroup(name = "DEAImport")
public class DEAImportCommands {

    private static final Logger LOGGER = LogManager.getLogger(DEAImportCommands.class);

    /*
    @MCRCommand(syntax = "import blumenbach tei folders from root {0}", order = 1)
    public static void importTEIFolders(String rootPath) throws MCRUploadServerException, IOException {
        LOGGER.info("Importing TEI folders from root {}", rootPath);

        Path path = Paths.get(rootPath);
        if (!Files.exists(path)) {
            LOGGER.error("Path {} does not exist", rootPath);
            throw new IllegalArgumentException("Path " + rootPath + " does not exist");
        }

        DEATEIUploadHandler uploader = new DEATEIUploadHandler();

        MCRCategoryID id = MCRCategoryID.fromString("derivate_types:content");
        MCRMetaClassification classification = new MCRMetaClassification("classification", 0, null,
            id);
        try (Stream<Path> files = Files.list(path)) {
            files.forEach(file -> {
                try {
                    uploader.traverse(file, "blumenbach", List.of(classification));
                } catch (MCRUploadServerException | MCRInvalidFileException | IOException e) {
                    throw new MCRException("Error while processing directory " + file.toString(), e);
                }
            });

        }
    }

     */

    @MCRCommand(syntax = "import biblist with project id {1} from path {0}", order = 1)
    public static void importBiblList(String pathStr, String project) {
        Path path = Paths.get(pathStr);
        if (!Files.exists(path)) {
            LOGGER.error("Path {} does not exist", pathStr);
            throw new IllegalArgumentException("Path " + pathStr + " does not exist");
        }

        SAXBuilder builder = new SAXBuilder();
        Document biblListDocument;

        try (InputStream is = Files.newInputStream(path, StandardOpenOption.READ)) {
            biblListDocument = builder.build(is);
        } catch (IOException | JDOMException e) {
            throw new MCRException("Error while reading file " + pathStr, e);
        }

        XPathFactory xFactory = XPathFactory.instance();
        XPathExpression<Element> expr = xFactory.compile("/tei:TEI/tei:text/tei:body/tei:listBibl/tei:biblStruct", Filters.element(), null, TEI_NS);
        List<Element> biblStructElementList = expr.evaluate(biblListDocument);

        biblStructElementList.forEach(biblStructElement -> {
            String id = biblStructElement.getAttributeValue("id", Namespace.XML_NAMESPACE);

            if (id.equals("_")) {
                LOGGER.warn("Skipping biblStruct with id _");
                return;
            }

            MCRObjectID objectID = ShelfMarkMappingManager.getMappedMycoreID(id, project)
                    .map(MCRObjectID::getInstance)
                    .orElseGet(() -> MCRMetadataManager.getMCRObjectIDGenerator().getNextFreeId(project, "bibl"));

            boolean exists = MCRMetadataManager.exists(objectID);
            MCRObject object;
            if(exists) {
                object = MCRMetadataManager.retrieveMCRObject(objectID);
            } else {
                object = new MCRObject();
                object.setId(objectID);
                object.setSchema("datamodel-bibl.xsd");
                object.setImportMode(true);
            }
            object.getService().setState("published");
            DEAUtils.setTEI(object, biblStructElement);

            MCREditorOutValidator ev = null;
            try {
                ev = new MCREditorOutValidator(object.createXML(), objectID);
                ev.generateValidMyCoReObject();

            } catch (JDOMException|IOException e) {
                throw new MCRException("Error while validating bibl object!", e);
            }

            try {
                MCRMetadataManager.update(object);
            } catch (MCRAccessException e) {
                throw new MCRException("Error while saving bibl object!", e);
            }
        });

    }
}
