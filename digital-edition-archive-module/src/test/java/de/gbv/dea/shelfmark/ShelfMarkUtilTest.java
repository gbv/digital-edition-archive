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

import org.jdom2.Document;
import org.jdom2.JDOMException;
import org.jdom2.input.SAXBuilder;
import org.junit.Assert;
import org.junit.Test;
import org.mycore.common.MCRClassTools;
import org.mycore.common.MCRTestCase;

import java.io.IOException;
import java.io.InputStream;
import java.util.Optional;

public class ShelfMarkUtilTest extends MCRTestCase {

    @Test
    public void testGetShelfmark() {
        try(InputStream resourceAsStream = MCRClassTools.getClassLoader().getResourceAsStream("idno_test.xml")){
            Document doc = new SAXBuilder().build(resourceAsStream);
            Optional<String> shelfmark = ShelfMarkUtil.getShelfmark("dea_tei_00000001", doc.getRootElement());
            Assert.assertTrue(shelfmark.isPresent());
            Assert.assertEquals("fr_bpp_29_1_0001", shelfmark.get() );
        } catch (IOException e) {
            throw new RuntimeException(e);
        } catch (JDOMException e) {
            throw new RuntimeException(e);
        }

    }


}