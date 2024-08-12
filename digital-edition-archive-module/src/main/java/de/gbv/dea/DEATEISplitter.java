package de.gbv.dea;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jdom2.Attribute;
import org.jdom2.Content;
import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.filter.Filters;
import org.jdom2.xpath.XPathExpression;
import org.jdom2.xpath.XPathFactory;

import java.util.ArrayList;
import java.util.List;

import static de.gbv.dea.DEAUtils.TEI_NS;

public class DEATEISplitter {

    private static Logger LOGGER = LogManager.getLogger();

    private TeiFile original;

    private Element copyTarget;

    private List<TeiFile> splitDocumentList = new ArrayList<>();

    private int size = -1;

    public DEATEISplitter(TeiFile original) {
        this.original = original;
    }

    public boolean isSplitable() {
        XPathFactory xFactory = XPathFactory.instance();
        XPathExpression<Element> expr = xFactory.compile("//tei:pb", Filters.element(), null, TEI_NS);
        List<Element> elementList = expr.evaluate(this.original.doc());
        return elementList.size() > 0;
    }

    public int getEstimatedSize() {
        if (size == -1) {
            XPathFactory xFactory = XPathFactory.instance();
            XPathExpression<Element> expr = xFactory.compile("//tei:pb", Filters.element(), null, TEI_NS);
            List<Element> elementList = expr.evaluate(this.original.doc());
            size = elementList.size();
        }

        return size;
    }

    private Stub copyAncestors(Element pbElement, String name) {
        Element parent = pbElement;
        Element lastClone = null;
        Element firstClone = null;
        while ((parent = parent.getParentElement()) != null) {
            Element cloned = cloneElement(parent);
            if (firstClone == null) {
                firstClone = cloned;
            }
            if (lastClone != null) {
                cloned.addContent(lastClone);
            }
            lastClone = cloned;
        }

        TeiFile teiFile = new TeiFile(name, new Document(lastClone));
        this.splitDocumentList.add(teiFile);
        return new Stub(firstClone, teiFile);
    }

    private void traverse(Element element) {
        for (Content content : element.getContent()) {
            if (content instanceof Element) {
                Element contentElement = (Element) content;
                if (contentElement.getName().equals("pb")) {
                    var facs = contentElement.getAttributeValue("facs");
                    if(facs.startsWith("images/")){
                        facs = facs.substring("images/".length());
                    }
                    Stub newStub = copyAncestors(element, facs);
                    copyTarget = newStub.newEl;
                    continue;
                }
            }

            copyToNew(content);
        }
        copyTarget = copyTarget.getParentElement();
    }

    private void copyToNew(Content content) {
        if (content instanceof Element) {
            Element elementContent = (Element) content;
            Element cloned = cloneElement(elementContent);
            copyTarget.addContent(cloned);

            copyTarget = cloned;
            traverse(elementContent);
        } else {
            copyTarget.addContent(content.clone());
        }

    }

    private Element cloneElement(Element elementContent) {
        Element element = new Element(elementContent.getName(), elementContent.getNamespace());
        elementContent.getAttributes()
            .stream()
            .map(Attribute::clone)
            .forEach(element::setAttribute);

        return element;
    }

    public List<TeiFile> split() {
        if (splitDocumentList.size() > 0) {
            splitDocumentList = new ArrayList<>();
        }

        Element originalText = this.original.doc()
            .getRootElement().getChild("text", TEI_NS);

        Stub newStub = copyAncestors(originalText.getChildren().get(0), null);
        copyTarget = newStub.newEl;

        traverse(originalText);

        return splitDocumentList;
    }

    public record TeiFile(String name, Document doc) {
    }

    public record Stub(Element newEl, TeiFile teiFile) {
    }
}
