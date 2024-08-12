/*
 * This file is part of ***  M y C o R e  ***
 * See http://www.mycore.de/ for details.
 *
 * MyCoRe is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MyCoRe is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with MyCoRe.  If not, see <http://www.gnu.org/licenses/>.
 */

package de.gbv.dea;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Stream;

import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.JDOMException;
import org.mycore.frontend.xeditor.MCRXEditorPostProcessor;

public class DEATEISorter implements MCRXEditorPostProcessor {

    static final List<String> FILE_DESC_LEVEL_ORDER
        = Stream.of("editionStmt", "publicationStmt", "seriesStmt").toList();

    static final List<String> TEI_HEADER_LEVEL_ORDER
        = Stream.of("fileDesc", "encodingDesc", "profileDesc", "revisionDesc").toList();

    public static void sortTEIHeader(Element teiHeader) {
        teiHeader.sortChildren((a, b) -> {
            int aIndex = TEI_HEADER_LEVEL_ORDER.indexOf(a.getName());
            int bIndex = TEI_HEADER_LEVEL_ORDER.indexOf(b.getName());
            return Integer.compare(aIndex, bIndex);
        });

        teiHeader.getChildren()
            .stream()
            .filter((el) -> "fileDesc".equals(el.getName()))
            .forEach(DEATEISorter::sortFileDesc);
    }

    public static void sortFileDesc(Element element) {
        element.sortChildren((a, b) -> {
            int aIndex = FILE_DESC_LEVEL_ORDER.indexOf(a.getName());
            int bIndex = FILE_DESC_LEVEL_ORDER.indexOf(b.getName());
            return Integer.compare(aIndex, bIndex);
        });

    }

    @Override
    public Document process(Document document) throws IOException, JDOMException {
        Element mycoreObject = document.getRootElement();
        Element teiHeader = Optional.ofNullable(mycoreObject.getChild("metadata"))
                .map((metadata) -> metadata.getChild("def.teiContainer"))
                .map((defTeiContainer) -> defTeiContainer.getChild("teiContainer"))
                .map((teiContainer) -> teiContainer.getChild("teiHeader", DEAUtils.TEI_NS))
                .orElseThrow(() -> new JDOMException("No TEI header found"));

        sortTEIHeader(teiHeader);


        return document;
    }

    @Override
    public void setAttributes(Map<String, String> map) {
    }
}
