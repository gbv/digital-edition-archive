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

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xmlns:mcri18n="http://www.mycore.de/xslt/i18n"
                exclude-result-prefixes="mcri18n tei xsl"
                version="3.0">

    <xsl:template match="/mycoreobject[contains(@ID,'_bibl_')]" mode="frontpage">
        <h1 class="mb-5 text-center">
            <xsl:value-of
                    select="metadata/def.teiContainer/teiContainer/tei:biblStruct/tei:monogr/tei:title[@type='main']/text()"/>
        </h1>
        <xsl:apply-templates select="metadata/def.teiContainer/teiContainer/tei:biblStruct" mode="bibl"/>
    </xsl:template>


    <xsl:template match="tei:biblStruct" mode="bibl">
        <xsl:apply-templates select="tei:monogr" mode="bibl"/>

        <xsl:if test="count(tei:relatedItem) &gt; 0">
            <xsl:call-template name="displayMetadataKV">
                <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.relatedItem')"/>
                <xsl:with-param name="value">
                    <xsl:for-each select="tei:relatedItem">
                        <xsl:choose>
                            <xsl:when test="@type='onlineedition'">
                                <a class="relatedItem-link" href="{@target}" target="_blank">
                                    <xsl:value-of select="tei:ref/text()"/>
                                </a>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tei:monogr" mode="bibl">

        <xsl:apply-templates select="tei:title[not(@type='main')]" mode="bibl"/>
        <xsl:apply-templates select="tei:editor" mode="bibl"/>
        <xsl:apply-templates select="tei:edition" mode="bibl"/>
        <xsl:apply-templates select="tei:author" mode="bibl"/>
        <xsl:apply-templates select="tei:imprint" mode="bibl"/>
        <xsl:apply-templates select="tei:idno" mode="bibl"/>

        <xsl:if test="count(tei:extent) &gt; 0">
            <xsl:call-template name="displayMetadataKV">
                <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.extent')"/>
                <xsl:with-param name="value">
                    <xsl:for-each select="tei:extent">
                        <xsl:value-of select="text()"/>
                        <xsl:if test="position() != last()">
                            <br/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tei:title" mode="bibl">
        <xsl:call-template name="displayMetadataKV">
            <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.title')"/>
            <xsl:with-param name="value">
                <xsl:value-of select="text()"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="tei:edition" mode="bibl">
        <xsl:call-template name="displayMetadataKV">
            <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.edition')"/>
            <xsl:with-param name="value">
                <xsl:value-of select="text()"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="tei:author" mode="bibl">
        <xsl:call-template name="displayMetadataKV">
            <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.author')"/>
            <xsl:with-param name="value">
                <xsl:value-of select="tei:persName/text()"/> <!-- TODO fix ref -->
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="tei:editor" mode="bibl">
        <xsl:call-template name="displayMetadataKV">
            <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.editor')"/>
            <xsl:with-param name="value">
                <xsl:value-of select="tei:persName/text()"/> <!-- TODO fix ref -->
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="tei:imprint" mode="bibl">
        <xsl:apply-templates select="tei:pubPlace" mode="bibl"/>
        <xsl:apply-templates select="tei:publisher" mode="bibl"/>
        <xsl:apply-templates select="tei:date" mode="bibl"/>
    </xsl:template>

    <xsl:template match="tei:pubPlace" mode="bibl">
        <xsl:call-template name="displayMetadataKV">
            <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.pubPlace')"/>
            <xsl:with-param name="value">
                <xsl:choose>
                    <xsl:when test="starts-with(tei:placeName/@ref, 'GettyId:')">
                        <xsl:variable name="gettyID" select="substring-after(tei:placeName/@ref, 'GettyId:')"/>
                        <a href="https://www.getty.edu/vow/TGNFullDisplay?subjectid={$gettyID}&amp;english=Y&amp;find=&amp;place=&amp;nation="
                           target="_blank">
                            <xsl:value-of select="tei:placeName/text()"/>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="tei:placeName/text()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="tei:publisher" mode="bibl">
        <xsl:call-template name="displayMetadataKV">
            <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.publisher')"/>
            <xsl:with-param name="value">
                <xsl:value-of select="text()"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="tei:date" mode="bibl">
        <xsl:call-template name="displayMetadataKV">
            <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.date')"/>
            <xsl:with-param name="value">
                <xsl:value-of select="text()"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="tei:idno" mode="bibl">
        <xsl:call-template name="displayMetadataKV">
            <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.idno')"/>
            <xsl:with-param name="value">
                <xsl:value-of select="text()"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>


</xsl:stylesheet>