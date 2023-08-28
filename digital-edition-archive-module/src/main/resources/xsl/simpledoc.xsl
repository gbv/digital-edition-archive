<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:mcri18n="http://www.mycore.de/xslt/i18n"
  xmlns:mcrclass="http://www.mycore.de/xslt/classification"
  exclude-result-prefixes="xlink mcri18n">

  <xsl:template match="/mycoreobject[contains(@ID,'_simpledoc_')]" mode="frontpage">
    <h1>
      <xsl:value-of select="metadata/def.title/title" />
    </h1>

    <table class="table">
      <tr>
        <th>
          <xsl:value-of select="mcri18n:translate('docdetails.ID')" />
        </th>
        <td>
          <xsl:call-template name="objectLink">
            <xsl:with-param select="." name="mcrobj" />
          </xsl:call-template>
        </td>
      </tr>

      <xsl:if test="metadata/def.creator/creator">
        <tr>
          <th>
            <xsl:value-of select="mcri18n:translate('editor.label.author')" />
          </th>
          <td>
            <xsl:for-each select="metadata/def.creator/creator">
              <xsl:value-of select="." />
              <br />
            </xsl:for-each>
          </td>
        </tr>
      </xsl:if>

      <xsl:if test="metadata/def.date/date">
        <tr>
          <th>
            <xsl:value-of select="mcri18n:translate('editor.label.date')" />
          </th>
          <td>
            <xsl:value-of select="metadata/def.date/date" />
          </td>
        </tr>
      </xsl:if>
      <xsl:if test="metadata/def.language/language">
        <tr>
          <th>
            <xsl:value-of select="mcri18n:translate('editor.label.language')" />
          </th>
          <td>
            <xsl:for-each select="metadata/def.language/language">
              <xsl:variable name="class" select="mcrclass:category(./@classid, ./@categid)" />
              <xsl:value-of select="mcrclass:current-label-text($class)" />
            </xsl:for-each>
          </td>
        </tr>
      </xsl:if>
    </table>
  </xsl:template>

</xsl:stylesheet>
