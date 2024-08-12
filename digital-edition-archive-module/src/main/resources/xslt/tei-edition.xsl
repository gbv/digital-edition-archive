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
                xmlns:mcrclass="http://www.mycore.de/xslt/classification"
                xmlns:mcrderivate="http://www.mycore.de/xslt/derivate"
                version="3.0">

    <xsl:template match="/mycoreobject[contains(@ID,'_edition_')]" mode="frontpage">
        <xsl:apply-templates select="metadata/def.teiContainer/teiContainer/tei:teiHeader" mode="edition" />
        <xsl:call-template name="teiUploader" />
    </xsl:template>

    <xsl:template name="teiUploader">
        <script>
            window["mycoreUploadSettings"] = {
            webAppBaseURL:"<xsl:value-of select='$WebApplicationBaseURL' />"
            }
        </script>
        <script src="{$WebApplicationBaseURL}js/import-tei-snapshot.js"> </script>
        <script src="{$WebApplicationBaseURL}modules/webtools/upload/js/upload-api.js"> </script>
        <script src="{$WebApplicationBaseURL}modules/webtools/upload/js/upload-gui.js"> </script>
        <link rel="stylesheet" type="text/css" href="{$WebApplicationBaseURL}modules/webtools/upload/css/upload-gui.css" />


        <div class="import-tei-snapshot">
            <div class="file-upload-box well well-sm col-10 col-offset-1"
                 style="margin-top:1em"
                 data-upload-project="{@ID}"
                 data-upload-target="/"
                 data-upload-handler="tei"
            >

                <i class="fa fa-upload" style="float:left;font-size:275%;margin-right:0.5em"></i>
                <h5 style="margin-top:0px"><strong><xsl:value-of select="concat(' ', mcri18n:translate('fileupload.drop.headline.new-file'))"/></strong></h5>
                <xsl:copy-of select="parse-xml-fragment(concat(' ', mcri18n:translate('fileupload.drop.upload-file')))"/>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="tei:teiHeader" mode="edition">
        <xsl:apply-templates select="tei:fileDesc" mode="edition" />
        <xsl:apply-templates select="tei:encodingDesc" mode="edition" />
    </xsl:template>


    <xsl:template match="tei:fileDesc" mode="edition">
        <xsl:apply-templates select="tei:seriesStmt" mode="edition" />
        <xsl:apply-templates select="tei:editionStmt" mode="edition" />
        <xsl:apply-templates select="tei:publicationStmt" mode="edition" />
    </xsl:template>

    <xsl:template match="tei:seriesStmt" mode="edition">
        <xsl:if test="tei:title[@type='main']">
            <xsl:call-template name="displayMetadataKV">
                <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.series.main')"/>
                <xsl:with-param name="value">
                  <xsl:value-of select="tei:title[@type='main']/text()" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test="tei:title[@type='sub']">
            <xsl:call-template name="displayMetadataKV">
                <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.series.sub')"/>
                <xsl:with-param name="value">
                  <xsl:value-of select="tei:title[@type='sub']/text()" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tei:editionStmt" mode="edition">
        <xsl:apply-templates select="tei:edition" mode="edition" />
        <xsl:apply-templates select="tei:editor" mode="edition" />
        <xsl:apply-templates select="tei:respStmt" mode="edition" />
    </xsl:template>

    <xsl:template match="tei:edition" mode="edition">
        <xsl:call-template name="displayMetadataKV">
            <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.edition_name')"/>
            <xsl:with-param name="value">
              <xsl:value-of select="text()" />
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>


    <xsl:template match="tei:editor" mode="edition">
        <xsl:call-template name="displayMetadataKV">
            <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.editor')"/>
            <xsl:with-param name="value">
              <xsl:value-of select="string-join(tei:persName/tei:*/text(), ',')" />
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="tei:respStmt" mode="edition">


        <xsl:if test="tei:persName">
            <xsl:call-template name="displayMetadataKV">
                <xsl:with-param name="key">
                    <xsl:variable name="categoryNode" select="mcrclass:category('marcrelator', tei:resp/@ref)" />
                    <xsl:value-of select="mcrclass:current-label-text($categoryNode)" />:
                </xsl:with-param>
                <xsl:with-param name="value">
                  <xsl:value-of select="string-join(tei:persName/tei:*/text(), ',')" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>

    </xsl:template>


    <xsl:template match="tei:publicationStmt" mode="edition">
        <xsl:if test="tei:publisher">
            <xsl:call-template name="displayMetadataKV">
                <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.hostingInstitution')"/>
                <xsl:with-param name="value">
                  <xsl:value-of select="tei:publisher/tei:orgName[@role='hostingInstitution']/text()" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test="tei:date">
            <xsl:call-template name="displayMetadataKV">
                <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.date')"/>
                <xsl:with-param name="value">
                  <xsl:value-of select="tei:date/text()" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test="tei:pubPlace">
            <xsl:call-template name="displayMetadataKV">
                <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.pubPlace')"/>
                <xsl:with-param name="value">
                  <xsl:value-of select="tei:pubPlace/text()" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test="tei:availability[@corresp ='#text']">
            <xsl:call-template name="displayMetadataKV">
                <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.availability.text')"/>
                <xsl:with-param name="value">
                    <xsl:variable name="categoryNode" select="mcrclass:category('mir_licenses', tei:availability[@corresp = '#text']/tei:licence/@target)" />
                    <xsl:value-of select="mcrclass:current-label-text($categoryNode)" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test="tei:availability[@corresp ='#image']">
            <xsl:call-template name="displayMetadataKV">
                <xsl:with-param name="key" select="mcri18n:translate('metadata.tei.availability.image')"/>
                <xsl:with-param name="value">
                    <xsl:variable name="categoryNode" select="mcrclass:category('mir_licenses', tei:availability[@corresp = '#image']/tei:licence/@target)" />
                    <xsl:value-of select="mcrclass:current-label-text($categoryNode)" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>