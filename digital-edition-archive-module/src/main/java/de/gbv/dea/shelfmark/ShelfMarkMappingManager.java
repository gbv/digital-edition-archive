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

import org.mycore.backend.jpa.MCREntityManagerProvider;
import org.mycore.datamodel.metadata.MCRObjectID;

import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import jakarta.persistence.TypedQuery;

public class ShelfMarkMappingManager {

    /**
     * Get the shelfmark mapped to a MyCoRe ID
     * @param mycoreID the MyCoRe ID
     * @return the shelfmark mapped to the MyCoRe ID
     */
    public static Optional<String> getMappedShelfmark(MCRObjectID mycoreID) {
        EntityManager em = MCREntityManagerProvider.getCurrentEntityManager();
        try {
            return Optional
                .of(ShelfMarkMapping
                    .createFindByMycoreIdAndProjectQuery(em, mycoreID.toString(), mycoreID.getProjectId())
                    .getSingleResult().getShelfMark());
        } catch (NoResultException noResultException) {
            return Optional.empty();
        }
    }

    /**
     * Get the number of shelfmarks mapped to a MyCoRe ID (0 or 1)
     * @param mycoreID the MyCoRe ID
     * @return the number of shelfmarks mapped to the MyCoRe ID
     */
    public static Long getMappedShelfmarkCount(MCRObjectID mycoreID) {
        EntityManager em = MCREntityManagerProvider.getCurrentEntityManager();
        TypedQuery<Long> countByMycoreIdQuery
            = ShelfMarkMapping.createCountByMycoreIdQuery(em, mycoreID.toString(), mycoreID.getProjectId());
        return countByMycoreIdQuery.getSingleResult();
    }

    /**
     * Get the MyCoRe ID mapped to a shelfmark
     * @param shelfmark the shelfmark
     * @return the MyCoRe ID mapped to the shelfmark
     */
    public static Optional<String> getMappedMycoreID(String shelfmark, String project) {
        EntityManager em = MCREntityManagerProvider.getCurrentEntityManager();
        try {
            return Optional.of(ShelfMarkMapping.createFindByShelfmarkAndProjectQuery(em, shelfmark, project)
                .getSingleResult().getMyCoReID());
        } catch (NoResultException noResultException) {
            return Optional.empty();
        }
    }

    /**
     * Get the number of MyCoRe IDs mapped to a shelfmark (0 or 1)
     * @param shelfmark the shelfmark
     * @return the number of MyCoRe IDs mapped to the shelfmark
     */
    public static Long getMappedMycoreIDCount(String shelfmark, String project) {
        EntityManager em = MCREntityManagerProvider.getCurrentEntityManager();
        TypedQuery<Long> countByShelfMarkQuery = ShelfMarkMapping.createCountByShelfmarkQuery(em, shelfmark, project);
        return countByShelfMarkQuery.getSingleResult();
    }

    /**
     * Map a shelfmark to a MyCoRe ID
     * @param shelfmark the shelfmark
     * @param mycoreID the MyCoRe ID
     * @throws IllegalArgumentException if the shelfmark or MyCoRe ID is already mapped
     */
    public static void mapShelfmark(String shelfmark, MCRObjectID mycoreID)
        throws IllegalArgumentException {
        if (getMappedMycoreIDCount(shelfmark, mycoreID.getProjectId()) > 0) {
            throw new IllegalArgumentException("Shelfmark already mapped");
        }

        if (getMappedShelfmarkCount(mycoreID) > 0) {
            throw new IllegalArgumentException("MycoreID already mapped");
        }

        EntityManager em = MCREntityManagerProvider.getCurrentEntityManager();
        ShelfMarkMapping shelfmarkMapping
            = new ShelfMarkMapping(shelfmark, mycoreID.toString(), mycoreID.getProjectId());
        em.persist(shelfmarkMapping);
    }

    /**
     * Remove all mappings to a MyCoRe ID
     * @param shelfmark the shelfmark
     */
    public static void removeMappingByShelfmarkAndProject(String shelfmark, String project) {
        EntityManager em = MCREntityManagerProvider.getCurrentEntityManager();

        ShelfMarkMapping.createFindByShelfmarkAndProjectQuery(em, shelfmark, project)
            .getResultList().forEach(em::remove);
    }

    /**
     * Remove all mappings to a MyCoRe ID
     * @param mycoreID the MyCoRe ID
     */
    public static void removeMappingByMycoreID(MCRObjectID mycoreID) {
        EntityManager em = MCREntityManagerProvider.getCurrentEntityManager();

        ShelfMarkMapping.createFindByMycoreIdAndProjectQuery(em, mycoreID.toString(), mycoreID.getProjectId())
            .getResultList().forEach(em::remove);
    }

}
