package de.gbv.dea;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.mycore.datamodel.niofs.MCRPath;
import org.mycore.mets.model.Mets;
import org.mycore.mets.model.files.FLocat;
import org.mycore.mets.model.files.File;
import org.mycore.mets.model.files.FileGrp;
import org.mycore.mets.model.struct.Fptr;
import org.mycore.mets.model.struct.LOCTYPE;
import org.mycore.mets.model.struct.LogicalDiv;
import org.mycore.mets.model.struct.PhysicalDiv;
import org.mycore.mets.model.struct.PhysicalSubDiv;
import org.mycore.mets.model.struct.SmLink;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Stream;

public class DEATEIMetsGenerator {

    private Mets mets;

    private List<DEATEISplitter.TeiFile> teiFiles;
    private final String title;

    private MCRPath fileRoot;

    private static final Logger LOGGER = LogManager.getLogger();
    private PhysicalDiv mainDiv;

    DEATEIMetsGenerator(MCRPath fileRoot, List<DEATEISplitter.TeiFile> teiFiles, String title) {
        this.fileRoot = fileRoot;
        this.teiFiles = teiFiles;
        this.title = title;
        this.mets = new Mets();
    }

    public List<DEATEISplitter.TeiFile> getTeiFiles() {
        return teiFiles;
    }

    public MCRPath getFileRoot() {
        return fileRoot;
    }

    public Mets getMets() {
        return mets;
    }

    public void generate() throws IOException {
        List<MCRPath> files;
        try(Stream<Path> file =  Files.walk(fileRoot)){
            files = file.map(MCRPath::toMCRPath).toList();
        }

        FileGrp masterFileGroup = new FileGrp("MASTER");
        mets.getFileSec().addFileGrp(masterFileGroup);

        FileGrp transcriptionFileGroup = new FileGrp("TEI.TRANSCRIPTION");
        mets.getFileSec().addFileGrp(transcriptionFileGroup);

        mainDiv = new PhysicalDiv("phys_" + UUID.randomUUID(), "physSequence");
        mets.getPhysicalStructMap().setDivContainer(mainDiv);

        String mainLogicalID = "log_" + UUID.randomUUID();
        mets.getLogicalStructMap().setDivContainer(new LogicalDiv(mainLogicalID, "monograph", title));

        int fileCount = 0;

        for (DEATEISplitter.TeiFile teiFile : teiFiles) {
            String name = teiFile.name();
            Optional<MCRPath> file = files.stream()
                    .map(p -> findMatchingFile(name, files))
                    .filter(Objects::nonNull)
                    .findFirst();

            if(file.isEmpty()){
                LOGGER.warn("No file found for " + name);
                continue;
            }

            String contentType = Files.probeContentType(file.get());

            String masterFileID = "file_master_" + UUID.randomUUID();
            File metsFile = new File(masterFileID, contentType);
            metsFile.setFLocat(new FLocat(LOCTYPE.URL, file.get().getOwnerRelativePath().substring(1)));
            masterFileGroup.addFile(metsFile);

            String transcriptionFileID = "file_transcription_" + UUID.randomUUID();
            File metsTranscriptionFile = new File(transcriptionFileID, "text/xml");
            MCRPath transcriptionPath = MCRPath.toMCRPath(fileRoot.resolve("tei/transcription/" + DEAUtils.removeFileEnding(name) + ".xml"));
            metsTranscriptionFile.setFLocat(new FLocat(LOCTYPE.URL, transcriptionPath.getOwnerRelativePath().substring(1)));
            transcriptionFileGroup.addFile(metsTranscriptionFile);

            mets.getPhysicalStructMap().setDivContainer(mainDiv);
            String physID = "phys_" + UUID.randomUUID();
            PhysicalSubDiv page = new PhysicalSubDiv(physID, "page");

            if(teiFile.n() != null) {
                page.setOrderLabel(teiFile.n());
            } else {
                page.setOrderLabel(String.valueOf(++fileCount));
            }

            page.add(new Fptr(masterFileID));
            page.add(new Fptr(transcriptionFileID));
            mainDiv.add(page);

            mets.getStructLink().addSmLink(new SmLink(mainLogicalID, physID));
        }

    }

    public MCRPath findMatchingFile(String name, List<MCRPath> files) {
        return files.stream()
                .filter(p -> p.getOwnerRelativePath()
                .equals("/" + name))
                .findFirst()
                .orElse(null);
    }
}
