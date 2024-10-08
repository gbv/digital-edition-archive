<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mcri18n="http://www.mycore.de/xslt/i18n"
                exclude-result-prefixes="mcri18n">

    <xsl:template match="import-tei-snapshot">
        <xsl:variable name="project" select="@project"/>
        <xsl:variable name="uploadHandler" select="@uploadHandler" />
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
                 data-upload-project="{$project}"
                 data-upload-target="/"
                 data-upload-handler="{$uploadHandler}"
            >

                <i class="fa fa-upload" style="float:left;font-size:275%;margin-right:0.5em"></i>
                <h5 style="margin-top:0px"><strong><xsl:value-of select="concat(' ', mcri18n:translate('fileupload.drop.headline.new-file'))"/></strong></h5>
                <xsl:copy-of select="parse-xml-fragment(concat(' ', mcri18n:translate('fileupload.drop.upload-file')))"/>
            </div>
        </div>
    </xsl:template>

</xsl:stylesheet>