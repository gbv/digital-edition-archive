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

import java.util.Optional;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jdom2.Element;
import org.mycore.common.MCRException;
import org.mycore.common.events.MCREvent;
import org.mycore.common.events.MCREventHandlerBase;
import org.mycore.datamodel.metadata.MCRObject;

import de.gbv.dea.DEAUtils;

public class ShelfMarkMappingEventHandler extends MCREventHandlerBase {

    private static final Logger LOGGER = LogManager.getLogger();

    private static Optional<String> extractShelfMark(MCRObject obj) {
        if (checkObjectType(obj)) {
            return Optional.empty();
        }

        Optional<Element> tei = extractTEI(obj);
        if(tei.isEmpty()) {
            return Optional.empty();
        } else {
            LOGGER.info("TEI found in object {}", obj.getId());
        }

        return ShelfMarkUtil.getShelfmark(obj.getId().toString(), tei.get());
    }

    private static Optional<Element> extractTEI(MCRObject obj) {
        Optional<Element> tei = Optional.ofNullable(DEAUtils.getTEI(obj));
        if (tei.isEmpty()) {
            LOGGER.info("No TEI found in object {}", obj.getId());
        }
        return tei;
    }

    private static boolean checkObjectType(MCRObject obj) {
        if (!obj.getId().getTypeId().equals("tei")) {
            LOGGER.info("Object {} is not a TEI object (skip it)", obj.getId());
            return true;
        }
        return false;
    }

    @Override
    protected void handleObjectCreated(MCREvent evt, MCRObject obj) {
        Optional<String> shelfmarkOpt = extractShelfMark(obj);
        if (shelfmarkOpt.isEmpty()) {
            return;
        }

        String projectId = obj.getId().getProjectId();
        String shelfmark = shelfmarkOpt.get();
        Optional<String> optMyCoReObject = ShelfMarkMappingManager.getMappedMycoreID(shelfmark, projectId);
        if (optMyCoReObject.isPresent()) {
            throw new MCRException("ShelfMark " + shelfmark + " already mapped to MyCoRe ID " + optMyCoReObject.get());
        } else {
            LOGGER.info("Map ShelfMark {} to MyCoRe ID {}", shelfmark, obj.getId());
            ShelfMarkMappingManager.mapShelfmark(shelfmark, obj.getId());
        }
    }

    @Override
    protected void handleObjectDeleted(MCREvent evt, MCRObject obj) {
        extractShelfMark(obj).ifPresent(shelfMark -> {
            String projectId = obj.getId().getProjectId();
            Optional<String> optMyCoReObject = ShelfMarkMappingManager.getMappedMycoreID(shelfMark, projectId);
            if (optMyCoReObject.isPresent()) {
                LOGGER.info("Unmap ShelfMark {} from MyCoRe ID {}", shelfMark, obj.getId());
                ShelfMarkMappingManager.removeMappingByShelfmarkAndProject(shelfMark, projectId);
            }
        });
    }

    @Override
    protected void handleObjectUpdated(MCREvent evt, MCRObject obj) {
        handleObjectDeleted(evt, obj);
        handleObjectCreated(evt, obj);
    }

}
