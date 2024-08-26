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

package de.gbv.dea.shelfmark;

import static de.gbv.dea.DEAUtils.TEI_NS;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jdom2.Attribute;
import org.jdom2.Element;
import org.jdom2.filter.Filters;
import org.jdom2.xpath.XPathExpression;
import org.jdom2.xpath.XPathFactory;
import org.mycore.common.MCRConstants;

public class ShelfMarkUtil {

    private static final Logger LOGGER = LogManager.getLogger();

    public static Optional<String> getShelfmark(String objectID, Element tei) {
        XPathFactory xFactory = XPathFactory.instance();
        XPathExpression<Attribute> expr = xFactory.compile(
                "(.|/tei:teiHeader)/tei:fileDesc/@xml:id",
                Filters.attribute(), null, TEI_NS, MCRConstants.XML_NAMESPACE);

        List<Attribute> xpResult = expr.evaluate(tei);
        if (xpResult.isEmpty()) {
            LOGGER.warn("No shelfmark found in object {}", objectID);
            return Optional.empty();
        }

        if (xpResult.size() > 1) {
            LOGGER.warn("Multiple shelfmarks found in object {} -> {}", objectID,
                    xpResult.stream().map(Attribute::getValue).collect(Collectors.joining()));
            return Optional.empty();
        }
        return Optional.of(xpResult.get(0).getValue());
    }

}
