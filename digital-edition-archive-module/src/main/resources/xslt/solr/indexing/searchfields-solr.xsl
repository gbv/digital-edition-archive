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
        <field name="digital-edition-archive.title">
            <xsl:value-of select="metadata/def.teiContainer/teiContainer/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type='main']"/>
        </field>

        <xsl:apply-templates select="metadata/def.teiContainer/teiContainer/tei:teiHeader"/>
    </xsl:template>

    <xsl:template match="tei:teiHeader">
        <xsl:apply-templates select="tei:fileDesc/tei:titleStmt/tei:title[@type='main']" />
        <xsl:apply-templates select="tei:fileDesc/tei:publicationStmt/tei:author"/>
        <xsl:apply-templates select="tei:fileDesc/tei:publicationStmt/tei:editor"/>
        <xsl:apply-templates select="tei:fileDesc/tei:publicationStmt/tei:publisher"/>
    </xsl:template>

    <xsl:template match="tei:title">
        <field name="dea.tei.title">
            <xsl:value-of select="."/>
        </field>
    </xsl:template>


    <xsl:template match="tei:author">
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

    <xsl:template match="tei:editor">
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

    <xsl:template match="tei:publisher">
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

    <xsl:template match="tei:persName">
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

    <xsl:template match="tei:orgName">
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