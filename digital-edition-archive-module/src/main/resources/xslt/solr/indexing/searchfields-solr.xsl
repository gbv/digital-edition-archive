<?xml version="1.0" encoding="UTF-8"?>
<!--
  ~ This file is part of ***  M y C o R e  ***
  ~ See http://www.mycore.de/ for details.
  ~
  ~ MyCoRe is free software: you can redistribute it and/or modify
  ~ it under the terms of the GNU General Public License as published by
  ~ the Free Software Foundation, either version 3 of the License, or
  ~ (at your option) any later version.
  ~
  ~ MyCoRe is distributed in the hope that it will be useful,
  ~ but WITHOUT ANY WARRANTY; without even the implied warranty of
  ~ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  ~ GNU General Public License for more details.
  ~
  ~ You should have received a copy of the GNU General Public License
  ~ along with MyCoRe.  If not, see <http://www.gnu.org/licenses/>.
  -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="3.0">

    <xsl:import href="xslImport:solr-document:solr/indexing/searchfields-solr.xsl"/>

    <xsl:template match="mycoreobject">
        <xsl:apply-imports/>

        <field name="digital-edition-archive.hasFiles">
            <xsl:value-of select="count(structure/derobjects/derobject)&gt;0"/>
        </field>


        <xsl:variable name="type" select="substring-before(substring-after(@ID,'_'), '_')"/>
        <xsl:choose>
            <xsl:when test="$type = 'tei'">
                <field name="digital-edition-archive.title">
                    <xsl:value-of
                            select="metadata/def.teiContainer/teiContainer/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type='main']"/>
                </field>
                <xsl:apply-templates select="metadata/def.teiContainer/teiContainer/tei:teiHeader" mode="tei"/>
            </xsl:when>
            <xsl:when test="$type = 'edition'">
                <field name="digital-edition-archive.title">
                    <xsl:value-of
                            select="metadata/def.teiContainer/teiContainer/tei:teiHeader/tei:fileDesc/tei:editionStmt/tei:edition"/>
                </field>
                <xsl:apply-templates select="metadata/def.teiContainer/teiContainer/tei:teiHeader"
                                     mode="edition"/>
            </xsl:when>
            <xsl:when test="$type='bibl'">
                <field name="digital-edition-archive.title">
                    <xsl:value-of
                            select="metadata/def.teiContainer/teiContainer/tei:biblStruct/tei:monogr/tei:title[@type='main']"/>
                </field>
            </xsl:when>
            <xsl:otherwise>
                <field name="digital-edition-archive.title">
                    <xsl:value-of select="@ID"/>
                </field>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- Edition -->

    <xsl:template match="tei:teiHeader" mode="edition">
        <xsl:apply-templates select="tei:fileDesc/tei:editionStmt/tei:edition" mode="edition"/>
        <xsl:apply-templates select="tei:fileDesc/tei:editionStmt/tei:editor" mode="edition"/>
        <xsl:apply-templates select="tei:fileDesc/tei:editionStmt/tei:publicationStmt/tei:respStmt" mode="edition"/>

    </xsl:template>

    <xsl:template match="tei:edition" mode="edition">
        <field name="dea.edition.title">
            <xsl:value-of select="."/>
        </field>
    </xsl:template>

    <xsl:template match="tei:editor" mode="edition">
        <xsl:if test="string-length(tei:persName/tei:forename) &gt; 0">
            <field name="dea.edition.editor.forename">
                <xsl:value-of select="tei:persName/tei:forename"/>
            </field>
        </xsl:if>
        <xsl:if test="string-length(tei:persName/tei:surname) &gt; 0">
            <field name="dea.edition.editor.surname">
                <xsl:value-of select="tei:persName/tei:surname"/>
            </field>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tei:respStmt" mode="edition">
        <xsl:if test="tei:resp and tei:persName/tei:forename">
            <field name="dea.edition.resp.forename">
                <xsl:value-of select="concat(tei:resp, ':' ,tei:persName/tei:forename)"/>
            </field>
        </xsl:if>

        <xsl:if test="tei:resp and tei:persName/tei:surname">
            <field name="dea.edition.resp.surname">
                <xsl:value-of select="concat(tei:resp, ':' ,tei:persName/tei:surname)"/>
            </field>
        </xsl:if>
    </xsl:template>


    <!-- TEI -->

    <xsl:template match="tei:teiHeader" mode="tei">
        <xsl:apply-templates select="tei:fileDesc/tei:titleStmt/tei:title[@type='main']" mode="tei"/>
        <xsl:apply-templates select="tei:fileDesc/tei:publicationStmt/tei:author" mode="tei"/>
        <xsl:apply-templates select="tei:fileDesc/tei:publicationStmt/tei:editor" mode="tei"/>
        <xsl:apply-templates select="tei:fileDesc/tei:publicationStmt/tei:publisher" mode="tei"/>
    </xsl:template>

    <xsl:template match="tei:title" mode="tei">
        <field name="dea.tei.title">
            <xsl:value-of select="."/>
        </field>
    </xsl:template>


    <xsl:template match="tei:author" mode="tei">
        <field name="dea.tei.author.plain">
            <xsl:value-of select="."/>
        </field>
        <xsl:apply-templates select="tei:persName">
            <xsl:with-param name="role" select="'author'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="tei:orgName">
            <xsl:with-param name="role" select="'author'"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="tei:editor" mode="tei">
        <field name="dea.tei.editor.plain">
            <xsl:value-of select="."/>
        </field>
        <xsl:apply-templates select="tei:persName">
            <xsl:with-param name="role" select="'editor'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="tei:orgName">
            <xsl:with-param name="role" select="'editor'"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="tei:publisher" mode="tei">
        <field name="dea.tei.publisher.plain">
            <xsl:value-of select="."/>
        </field>
        <xsl:apply-templates select="tei:persName">
            <xsl:with-param name="role" select="'publisher'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="tei:orgName">
            <xsl:with-param name="role" select="'publisher'"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="tei:persName" mode="tei">
        <xsl:param name="role"/>

        <xsl:choose>
            <xsl:when test="$role = 'author'">
                <field name="dea.tei.author.persName">
                    <xsl:value-of select="."/>
                </field>
            </xsl:when>
            <xsl:when test="$role = 'editor'">
                <field name="dea.tei.editor.persName">
                    <xsl:value-of select="."/>
                </field>
            </xsl:when>
            <xsl:when test="$role = 'publisher'">
                <field name="dea.tei.publisher.persName">
                    <xsl:value-of select="."/>
                </field>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:orgName" mode="tei">
        <xsl:param name="role"/>

        <xsl:choose>
            <xsl:when test="$role = 'author'">
                <field name="dea.tei.author.orgName">
                    <xsl:value-of select="."/>
                </field>
            </xsl:when>
            <xsl:when test="$role = 'editor'">
                <field name="dea.tei.editor.orgName">
                    <xsl:value-of select="."/>
                </field>
            </xsl:when>
            <xsl:when test="$role = 'publisher'">
                <field name="dea.tei.publisher.orgName">
                    <xsl:value-of select="."/>
                </field>
            </xsl:when>
        </xsl:choose>
    </xsl:template>


</xsl:stylesheet>