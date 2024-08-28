package de.gbv.dea.iiif;

import de.gbv.dea.DEAUtils;
import org.jdom2.Element;
import org.jdom2.filter.Filters;
import org.jdom2.xpath.XPathFactory;
import org.mycore.access.MCRAccessException;
import org.mycore.common.MCRException;
import org.mycore.datamodel.metadata.MCRMetaEnrichedLinkID;
import org.mycore.datamodel.metadata.MCRMetadataManager;
import org.mycore.datamodel.metadata.MCRObject;
import org.mycore.datamodel.metadata.MCRObjectID;
import org.mycore.datamodel.niofs.MCRPath;
import org.mycore.iiif.image.impl.MCRIIIFImageImpl;
import org.mycore.iiif.image.impl.MCRIIIFImageNotFoundException;
import org.mycore.iiif.image.impl.MCRIIIFImageProvidingException;
import org.mycore.iiif.image.model.MCRIIIFImageInformation;
import org.mycore.iiif.image.model.MCRIIIFImageProfile;
import org.mycore.iiif.presentation.impl.MCRIIIFPresentationImpl;
import org.mycore.iiif.presentation.model.additional.MCRIIIFAnnotation;
import org.mycore.iiif.presentation.model.attributes.MCRDCMIType;
import org.mycore.iiif.presentation.model.attributes.MCRIIIFResource;
import org.mycore.iiif.presentation.model.attributes.MCRIIIFService;
import org.mycore.iiif.presentation.model.basic.MCRIIIFCanvas;
import org.mycore.iiif.presentation.model.basic.MCRIIIFManifest;
import org.mycore.iiif.presentation.model.basic.MCRIIIFSequence;
import org.mycore.iview2.services.MCRIView2Tools;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Stream;

public class DEAIIIFPresentationImpl extends MCRIIIFPresentationImpl {

    public DEAIIIFPresentationImpl(String implName) {
        super(implName);
    }

    private static String getTitle(Element tei) {
        XPathFactory xPathFactory = XPathFactory.instance();
        return xPathFactory.compile("./tei:fileDesc/tei:titleStmt/tei:title[1]", Filters.element(), null, DEAUtils.TEI_NS).evaluateFirst(tei).getTextNormalize();
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
    public MCRIIIFManifest getManifest(String s) {
        MCRObject mcrObject = getMcrObject(s);
        MCRObjectID derivate = getDerivateID(s, mcrObject);

        MCRIIIFManifest manifest = new MCRIIIFManifest();
        Element teiElement = DEAUtils.getTEI(mcrObject);

        String title = getTitle(teiElement);
        manifest.setLabel(title);

        manifest.setId(s);

        MCRIIIFSequence sequence = new MCRIIIFSequence(s + "_sequence");
        sequence.canvases = new ArrayList<>();

        MCRPath derivatePath = MCRPath.getPath(derivate.toString(), "/");
        try (Stream<Path> stream = Files.walk(derivatePath)) {
            for (Path path : stream.sorted(Path::compareTo).toList()) {
                try {
                    if (!MCRIView2Tools.isFileSupported(path)) {
                        continue;
                    }
                } catch (IOException e) {
                    continue;
                }
                MCRIIIFImageInformation info;

                String identifier = derivate + ":" + path.getFileName().toString();
                try {
                    info = MCRIIIFImageImpl.getInstance("Iview").getInformation(identifier);
                } catch (MCRIIIFImageNotFoundException | MCRIIIFImageProvidingException | MCRAccessException e) {
                    continue;
                }

                MCRIIIFCanvas canvas = new MCRIIIFCanvas(identifier, identifier, info.width, info.height);
                MCRIIIFAnnotation annotation = new MCRIIIFAnnotation(identifier, canvas);

                MCRIIIFResource resource = new MCRIIIFResource(info.getId(), MCRDCMIType.Image);
                resource.setWidth(info.width);
                resource.setHeight(info.height);

                MCRIIIFService service = new MCRIIIFService(info.getId(), info.getContext());
                service.profile = MCRIIIFImageProfile.IIIF_PROFILE_2_0;
                resource.setService(service);

                annotation.setResource(resource);
                canvas.images.add(annotation);
                sequence.canvases.add(canvas);
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }


        manifest.sequences.add(sequence);

        return manifest;
    }
}
