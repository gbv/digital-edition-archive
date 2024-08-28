package de.gbv.dea.iiif;

import org.jdom2.Document;
import org.jdom2.JDOMException;
import org.jdom2.input.SAXBuilder;
import org.mycore.common.MCRException;
import org.mycore.datamodel.metadata.MCRMetaEnrichedLinkID;
import org.mycore.datamodel.metadata.MCRMetadataManager;
import org.mycore.datamodel.metadata.MCRObject;
import org.mycore.datamodel.metadata.MCRObjectID;
import org.mycore.datamodel.niofs.MCRPath;
import org.mycore.iiif.presentation.model.attributes.MCRIIIFMetadata;
import org.mycore.mets.iiif.MCRMetsIIIFPresentationImpl;
import org.mycore.mets.iiif.MCRMetsMods2IIIFConverter;
import org.mycore.mets.model.Mets;
import org.mycore.mets.model.files.File;
import org.mycore.mets.model.struct.LogicalDiv;
import org.mycore.mets.model.struct.PhysicalSubDiv;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

public class DEAIIIFPresentationImpl extends MCRMetsIIIFPresentationImpl {

    public DEAIIIFPresentationImpl(String implName) {
        super(implName);
    }

    private static MCRObjectID getDerivateID(String s, MCRObject mcrObject) {
        List<MCRMetaEnrichedLinkID> derivatesLinks = mcrObject.getStructure().getDerivates();
        if (derivatesLinks.isEmpty()) {
            throw new MCRException("No derivate found for object: " + s);
        }

        Optional<MCRMetaEnrichedLinkID> first = derivatesLinks.stream().filter(link -> {
            return link.getClassifications().stream().anyMatch(clazz -> {
                return Objects.equals(clazz.toString(), "derivate_types:content");
            });
        }).findFirst();

        if (first.isEmpty()) {
            throw new MCRException("No content derivate found for object: " + s);
        }

        MCRMetaEnrichedLinkID linkID = first.get();

        return linkID.getXLinkHrefID();
    }

    private static MCRObject getMcrObject(String s) {
        if (!MCRObjectID.isValid(s)) {
            throw new MCRException("Invalid object id: " + s);
        }

        MCRObjectID objectID = MCRObjectID.getInstance(s);
        if (!MCRMetadataManager.exists(objectID)) {
            throw new MCRException("Object not found: " + s);
        }

        MCRObject mcrObject = MCRMetadataManager.retrieveMCRObject(objectID);
        return mcrObject;
    }

    @Override
    public Document getMets(String id) throws IOException, JDOMException {
        MCRObject mcrObject = getMcrObject(id);
        MCRObjectID derivateID = getDerivateID(id, mcrObject);

        MCRPath mets = MCRPath.getPath(derivateID.toString(), "/mets.xml");
        if (!Files.exists(mets)) {
            throw new MCRException("METS file not found: " + mets);
        }

        try (InputStream in = Files.newInputStream(mets)) {
            return new SAXBuilder().build(in);
        }
    }


    @Override
    protected MCRMetsMods2IIIFConverter getConverter(String id, Document metsDocument) {
        MCRObject mcrObject = getMcrObject(id);
        MCRObjectID derivateID = getDerivateID(id, mcrObject);


        return new MCRMetsMods2IIIFConverter(metsDocument, id) {
            @Override
            protected List<MCRIIIFMetadata> extractMedataFromLogicalDiv(Mets mets, LogicalDiv divContainer) {
                return List.of(
                        new MCRIIIFMetadata("title", mets.getLogicalStructMap().getDivContainer().getLabel())
                );
            }


            @Override
            protected String getIIIFIdentifier(PhysicalSubDiv subDiv) {
                File file = subDiv.getChildren()
                        .stream()
                        .map(fptr -> imageGrp.getFileById(fptr.getFileId()))
                        .filter(Objects::nonNull)
                        .findAny().get();

                String href = file.getFLocat().getHref();
                return derivateID.toString() + "%3A" + href;
            }
        };
    }
}
