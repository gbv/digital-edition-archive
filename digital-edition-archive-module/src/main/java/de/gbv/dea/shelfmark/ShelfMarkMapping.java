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

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityManager;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.NamedQueries;
import jakarta.persistence.NamedQuery;
import jakarta.persistence.Table;
import jakarta.persistence.TypedQuery;
import jakarta.persistence.UniqueConstraint;

import java.util.Objects;

@Entity
@Table(name = "ShelfMarkMapping", uniqueConstraints = {
    @UniqueConstraint(columnNames = { "shelfMark", "project" }),
    @UniqueConstraint(columnNames = { "myCoReID"})
},
    indexes = {
        @Index(name = "idx_shelfmark", columnList = "shelfMark"),
        @Index(name = "idx_mycoreid", columnList = "myCoReID"),
        @Index(name = "idx_shelfmark_mycoreid", columnList = "shelfMark, myCoReID") })
@NamedQueries({
    @NamedQuery(name = "ShelfmarkMapping.findByShelfMarkAndProject",
        query = "SELECT sm FROM ShelfMarkMapping sm WHERE sm.shelfMark = :shelfmark and sm.project = :project"),
    @NamedQuery(name = "ShelfmarkMapping.findByMyCoReIDAndProject",
        query = "SELECT sm FROM ShelfMarkMapping sm WHERE sm.myCoReID = :mycoreid and sm.project = :project"),
    @NamedQuery(name = "ShelfmarkMapping.countByMyCoReIDAndProject",
        query = "SELECT COUNT(sm) FROM ShelfMarkMapping sm WHERE sm.myCoReID = :mycoreid and sm.project = :project"),
    @NamedQuery(name = "ShelfmarkMapping.countByShelfMarkAndProject",
        query = "SELECT COUNT(sm) FROM ShelfMarkMapping sm WHERE sm.shelfMark = :shelfmark and sm.project = :project"),
    @NamedQuery(name = "ShelfmarkMapping.findByMyCoReIDAndShelfMark",
        query = "SELECT sm FROM ShelfMarkMapping sm WHERE sm.myCoReID = :mycoreid AND sm.shelfMark = :shelfmark")
})
public class ShelfMarkMapping {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "shelfMark", length = 128, nullable = false)
    private String shelfMark;

    @Column(name = "myCoReID", length = 64, nullable = false)
    private String myCoReID;

    @Column(name = "project", length = 64, nullable = false)
    private String project;

    public ShelfMarkMapping() {
    }

    public ShelfMarkMapping(String shelfMark, String myCoReID, String project) {
        this.shelfMark = Objects.requireNonNull(shelfMark);
        this.myCoReID = Objects.requireNonNull(myCoReID);
        this.project = Objects.requireNonNull(project);
    }

    public static TypedQuery<Long> createCountByMycoreIdQuery(EntityManager em, String mycoreId, String project) {
        TypedQuery<Long> namedQuery = em.createNamedQuery("ShelfmarkMapping.countByMyCoReIDAndProject", Long.class);
        namedQuery.setParameter("mycoreid", mycoreId);
        namedQuery.setParameter("project", project);
        return namedQuery;
    }

    public static TypedQuery<Long> createCountByShelfmarkQuery(EntityManager em, String shelfMark, String project) {
        TypedQuery<Long> namedQuery = em.createNamedQuery("ShelfmarkMapping.countByShelfMarkAndProject", Long.class);
        namedQuery.setParameter("shelfmark", shelfMark);
        namedQuery.setParameter("project", project);

        return namedQuery;

    }

    public static TypedQuery<ShelfMarkMapping> createFindByMycoreIdAndProjectQuery(EntityManager em, String myCoReID,
                                                                                   String project) {
        TypedQuery<ShelfMarkMapping> namedQuery
            = em.createNamedQuery("ShelfmarkMapping.findByMyCoReIDAndProject", ShelfMarkMapping.class);
        namedQuery.setParameter("mycoreid", myCoReID);
        namedQuery.setParameter("project", project);
        return namedQuery;
    }

    public static TypedQuery<ShelfMarkMapping> createFindByShelfmarkAndProjectQuery(EntityManager em, String shelfMark,
                                                                                    String project) {
        TypedQuery<ShelfMarkMapping> namedQuery
            = em.createNamedQuery("ShelfmarkMapping.findByShelfMarkAndProject", ShelfMarkMapping.class);
        namedQuery.setParameter("shelfmark", shelfMark);
        namedQuery.setParameter("project", project);
        return namedQuery;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getShelfMark() {
        return shelfMark;
    }

    public void setShelfMark(String shelfmark) {
        this.shelfMark = shelfmark;
    }

    public String getMyCoReID() {
        return myCoReID;
    }

    public void setMyCoReID(String myCoReID) {
        this.myCoReID = myCoReID;
    }

    public String getProject() {
        return project;
    }

    public void setProject(String project) {
        this.project = project;
    }

    @Override
    public String toString() {
        return "ShelfmarkMapping[" +
            "id=" + id + ", " +
            "shelfmark=" + shelfMark + ", " +
            "myCoReID=" + myCoReID + ']';
    }

}
