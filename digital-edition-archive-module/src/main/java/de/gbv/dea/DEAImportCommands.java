package de.gbv.dea;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.mycore.common.MCRException;
import org.mycore.datamodel.classifications2.MCRCategoryID;
import org.mycore.datamodel.metadata.MCRMetaClassification;
import org.mycore.frontend.cli.annotation.MCRCommand;
import org.mycore.frontend.cli.annotation.MCRCommandGroup;
import org.mycore.webtools.upload.exception.MCRInvalidFileException;
import org.mycore.webtools.upload.exception.MCRUploadServerException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.stream.Stream;

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
}
