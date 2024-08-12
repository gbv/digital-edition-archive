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

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;

import org.junit.Test;
import org.mycore.common.MCRJPATestCase;
import org.mycore.datamodel.metadata.MCRObjectID;

public class ShelfMarkMappingManagerTest extends MCRJPATestCase {

    public String TEST_SHELFMARK_1 = "shelfmark";
    public String TEST_SHELFMARK_2 = "shelfmark2";

    public MCRObjectID testID1;
    public MCRObjectID testID2;

    public static final String TEST_PROJECT = "dea";

    @Override
    public void setUp() throws Exception {
        super.setUp();
        testID1 =  MCRObjectID.getInstance("dea_tei_00000002");
        testID2 =  MCRObjectID.getInstance("dea_tei_00000003");
    }

    @Test
    public void testGetMappedShelfmark() {

        Long count = ShelfMarkMappingManager.getMappedMycoreIDCount(TEST_SHELFMARK_1, TEST_PROJECT);
        assertEquals(0, count.longValue());

        ShelfMarkMappingManager.mapShelfmark(TEST_SHELFMARK_1, testID1);
        count = ShelfMarkMappingManager.getMappedMycoreIDCount(TEST_SHELFMARK_1, TEST_PROJECT);
        assertEquals(1, count.longValue());

        try {
            ShelfMarkMappingManager.mapShelfmark(TEST_SHELFMARK_1, testID2);
            fail("ShelfmarkMappingException expected");
        } catch (IllegalArgumentException e) {
            // expected
        }

        ShelfMarkMappingManager.mapShelfmark(TEST_SHELFMARK_2, testID2);
        count = ShelfMarkMappingManager.getMappedMycoreIDCount(TEST_SHELFMARK_2, TEST_PROJECT);
        assertEquals(1, count.longValue());

        assertEquals(testID1.toString(), ShelfMarkMappingManager.getMappedMycoreID(TEST_SHELFMARK_1, TEST_PROJECT).get());

        assertEquals(testID2.toString(), ShelfMarkMappingManager.getMappedMycoreID(TEST_SHELFMARK_2, TEST_PROJECT).get());

        ShelfMarkMappingManager.removeMappingByShelfmarkAndProject(TEST_SHELFMARK_1, TEST_PROJECT);
        count = ShelfMarkMappingManager.getMappedMycoreIDCount(TEST_SHELFMARK_1, TEST_PROJECT);
        assertEquals(0, count.longValue());

        ShelfMarkMappingManager.removeMappingByShelfmarkAndProject(TEST_SHELFMARK_2, TEST_PROJECT);
        count = ShelfMarkMappingManager.getMappedMycoreIDCount(TEST_SHELFMARK_2, TEST_PROJECT);
        assertEquals(0, count.longValue());

    }

}
