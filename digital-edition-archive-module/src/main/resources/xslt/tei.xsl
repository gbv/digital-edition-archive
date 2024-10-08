<?xml version="1.0" encoding="UTF-8" ?>
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
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:mcrproperty="http://www.mycore.de/xslt/property"
                xmlns:mcriview2="http://www.mycore.de/xslt/iview2"
                xmlns:mcracl="http://www.mycore.de/xslt/acl"
                xmlns:mcrderivate="http://www.mycore.de/xslt/derivate"
                exclude-result-prefixes="mcri18n tei xsl xlink mcrproperty mcriview2 mcracl mcrderivate"
                version="3.0">

    <!--  actual framework for display -->
    <xsl:template name="displayMetadataKV">
        <xsl:param name="key"/>
        <xsl:param name="value"/>

        <div class="row row-metadata">
            <div class="col-3 col-metadata-key">
                <xsl:copy-of select="$key"/>
            </div>
            <div class="col-9 col-metadata-value">
                <xsl:copy-of select="$value"/>
            </div>
        </div>
    </xsl:template>

    <!--
    <titleStmt>
      <title type="main">[Haupttitel]</title>
      <title type="sub">[Untertitel]</title>  ggf. mehrfach zu verwenden
        <title type="volume" n="[DTA-Bandnummer]">[Bandbezeichnung]</title> falls vorhanden
        <title type="part" n="[Nummer des Teils einer mehrteiligen unselbständigen Publikation]">
            [Titel des Teils einer mehrteiligen unselbständigen Publikation]
        </title> - falls vorhanden
        <author>[Autor]</author>  ggf. mehrfach zu verwenden
        <editor corresp="#[XML-ID des Publication Statements]">
            [Herausgeber der vorliegenden Textausgabe]
        </editor>  ggf. mehrfach zu verwenden
        <respStmt>[Verantwortlichkeit bei externen Beiträgern]</respStmt>
    </titleStmt>
    -->
    <xsl:template match="/mycoreobject[contains(@ID,'_tei_')]" mode="frontpage">
        <xsl:apply-templates select="metadata/def.teiContainer/teiContainer/tei:teiHeader" mode="tei"/>
    </xsl:template>

    <xsl:template match="tei:teiHeader" mode="tei">
        <xsl:apply-templates mode="tei" />
        <xsl:call-template name="displayDownloadLink"/>
    </xsl:template>

    <xsl:template name="displayDownloadLink">
        <xsl:variable name="originalDerivate"
                      select="ancestor::mycoreobject/structure/derobjects/derobject[count(classification[@classid='derivate_types' and @categid='original'])&gt;0][1]"/>
        <xsl:if test="$originalDerivate">
            <xsl:variable name="odId" select="$originalDerivate/@xlink:href"/>
            <xsl:variable name="odMainDoc" select="$originalDerivate/maindoc/text()"/>

            <xsl:if test="string-length($odId) &gt; 0 and string-length($odMainDoc) &gt; 0">
                <xsl:call-template name="displayMetadataKV">
                    <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.download')"/>
                    <xsl:with-param name="value">
                        <a href="{$WebApplicationBaseURL}servlets/MCRDerivateContentTransformerServlet/{$odId}/{$odMainDoc}"
                           download="{$odMainDoc}">
                            <xsl:value-of select="$odMainDoc"/>
                        </a>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:if>
        </xsl:if>


    </xsl:template>

    <xsl:template match="tei:fileDesc" mode="tei">
        <xsl:apply-templates mode="tei" />
    </xsl:template>

    <xsl:template match="tei:fileDesc/tei:titleStmt" mode="tei">
        <h2 class="heading-metadata">
            <xsl:for-each select="tei:title[@type='main']">
                <xsl:value-of select="."/>
            </xsl:for-each>
            <xsl:for-each select="tei:title[@type='sub']">
                <xsl:value-of select="."/>
            </xsl:for-each>
            <xsl:if test="tei:title[@type='part']">
                <xsl:value-of select="tei:title[@type='part']"/>
            </xsl:if>
        </h2>

        <xsl:for-each select="ancestor::mycoreobject/.//derobject">
            <xsl:call-template name="showViewer" />
        </xsl:for-each>

        <xsl:for-each select="tei:author">
            <xsl:call-template name="displayMetadataKV">
                <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.author')"/>
                <xsl:with-param name="value">
                    <xsl:apply-templates mode="displayMetadata" select="tei:persName/tei:surname" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="tei:editor">
            <xsl:call-template name="displayMetadataKV">
                <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.editor')"/>
                <xsl:with-param name="value">
                    <xsl:apply-templates mode="displayMetadata"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="tei:respStmt">
            <xsl:variable name="respStmtLabel">
                <xsl:apply-templates mode="displayMetadata" select="tei:resp"/>
            </xsl:variable>
            <xsl:call-template name="displayMetadataKV">
                <xsl:with-param name="key" select="$respStmtLabel"/>
                <xsl:with-param name="value">
                    <xsl:apply-templates mode="displayMetadata" select="*[local-name()!='resp']"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="showViewer">
        <xsl:variable name="objID" select="ancestor::mycoreobject/@ID" />
        <xsl:variable name="derId" select="@xlink:href" />
        <xsl:variable name="derivateXML" select="document(concat('mcrobject:',$derId))" />
        <xsl:variable name="supportedContentTypeStr" select="mcrproperty:one('MCR.Module-iview2.SupportedContentTypes')" />
        <xsl:variable name="mainFile" select="maindoc/text()"/>

        <xsl:if test="string-length($mainFile)&gt;0">
            <xsl:variable name="contentType" select="mcrderivate:get-file-content-type($derId, $mainFile)"/>
            <xsl:variable name="supportedContentTypes" select="tokenize($supportedContentTypeStr, ',')" />
            <xsl:variable name="isIview" select="$contentType = $supportedContentTypes"/>
            <xsl:variable name="isPDF" select="$contentType = 'application/pdf'"/>
            <xsl:variable name="isEpub" select="contains($mainFile, '.epub') and normalize-space(substring-after($mainFile, '.epub')) = ''" />
            <xsl:choose>
                <xsl:when test="$isIview or $isPDF or $isEpub">
                    <xsl:choose>
                        <xsl:when test="$isPDF or $isEpub or mcriview2:is-completely-tiled($derId)">
                            <xsl:variable name="viewerID" select="concat($derId,':/', $mainFile)" />
                            <div class="row row-viewer">
                                <div class="col-12">
                                    <div data-viewer="{$viewerID}" style="min-height:500px; position:relative;">
                                    </div>
                                </div>
                            </div>
                            <script src="{$WebApplicationBaseURL}rsc/viewer/{$derId}/{$mainFile}?embedded=true&amp;XSL.Style=js">
                            </script>
                        </xsl:when>
                        <xsl:otherwise>
                            <div class="card card-body bg-light row-no-viewer no-viewer">
                                <xsl:value-of select="mcri18n:translate-with-params('metaData.previewInProcessing', $derId)" />
                            </div>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:template>


    <xsl:template match="tei:resp" mode="displayMetadata">
        <xsl:choose>
            <!-- blumenbach simple text mode -->
            <!--
            <respStmt>
                <resp>Bearbeitung durch:</resp>
                <orgName xml:id="BjfbO">Bearbeiter des Projekts Johann Friedrich Blumenbach - online</orgName>
            </respStmt>
            -->
            <xsl:when test="count(*)=0">
                <xsl:variable name="respStmtLabelTranlated"
                              select="mcri18n:translate(concat('metadata.tei.respStmt.', text()))"/>
                <xsl:choose>
                    <xsl:when test="not(starts-with($respStmtLabelTranlated, '???'))">
                        <xsl:value-of select="$respStmtLabelTranlated"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="text()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- DTABF Mode: https://www.deutschestextarchiv.de/doku/basisformat/mdRespStmt.html -->
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:fileDesc/tei:editionStmt" mode="tei">
        <xsl:call-template name="displayMetadataKV">
            <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.edition')"/>
            <xsl:with-param name="value">
                        <xsl:apply-templates mode="displayMetadata" select="tei:edition"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="tei:fileDesc/tei:edition" mode="tei">

    </xsl:template>

    <xsl:template match="tei:fileDesc/tei:extent" mode="tei">
        <xsl:call-template name="displayMetadataKV">
            <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.fileDesc.extent')"/>
            <xsl:with-param name="value">
                <xsl:apply-templates mode="displayMetadata"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="tei:fileDesc/tei:publicationStmt" mode="tei">
        <xsl:for-each select="tei:publisher">
            <xsl:call-template name="displayMetadataKV">
                <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.publisher')"/>
                <xsl:with-param name="value">
                    <xsl:apply-templates mode="displayMetadata"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="tei:fileDesc/tei:notesStmt" mode="tei">
        <xsl:call-template name="displayMetadataKV">
            <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.noteStmt')"/>
            <xsl:with-param name="value">
                <xsl:apply-templates mode="displayMetadata"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="tei:note" mode="displayMetadata">
        <xsl:value-of select="."/>
    </xsl:template>

    <!--
    <xsl:template match="tei:" mode="displayMetadata">

    </xsl:template>
    -->

    <xsl:template match="tei:p" mode="displayMetadata">
        <xsl:apply-templates mode="displayMetadata"/>
    </xsl:template>

    <xsl:template match="tei:placeName" mode="displayMetadata">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template match="tei:orgName" mode="displayMetadata">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template match="tei:persName" mode="displayMetadata">
        <xsl:value-of select="."/>
    </xsl:template>

</xsl:stylesheet>