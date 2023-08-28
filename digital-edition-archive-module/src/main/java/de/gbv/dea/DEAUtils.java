package de.gbv.dea;

import org.jdom2.Content;
import org.jdom2.Element;
import org.jdom2.Namespace;
import org.mycore.datamodel.metadata.MCRMetaElement;
import org.mycore.datamodel.metadata.MCRMetaXML;
import org.mycore.datamodel.metadata.MCRObject;
import org.mycore.datamodel.metadata.MCRObjectMetadata;

import java.util.Collections;
import java.util.List;

public class DEAUtils {
    public static final Namespace TEI_NS = Namespace.getNamespace("http://www.tei-c.org/ns/1.0");
    public static final String DEF_TEI_CONTAINER = "def.teiContainer";

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
        MCRMetaXML teiContainer = new MCRMetaXML(DEF_TEI_CONTAINER, null, 0);
        List<MCRMetaXML> list = Collections.nCopies(1, teiContainer);
        MCRMetaElement defTeiContainer = new MCRMetaElement(MCRMetaXML.class, DEF_TEI_CONTAINER, false, true, list);
        om.setMetadataElement(defTeiContainer);
        teiContainer.addContent(tei);
    }
}
