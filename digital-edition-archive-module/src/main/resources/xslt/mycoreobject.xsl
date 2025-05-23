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

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:mcracl="http://www.mycore.de/xslt/acl"
                xmlns:mcri18n="http://www.mycore.de/xslt/i18n"
                xmlns:mcr="http://www.mycore.org/"
                xmlns:mcrurl="http://www.mycore.de/xslt/url"
                exclude-result-prefixes="xlink mcr mcri18n mcracl">
  <xsl:include href="MyCoReLayout.xsl"/>
  <!-- include custom templates for supported objecttypes -->
  <xsl:include href="xslInclude:objectTypes"/>
  <xsl:variable name="PageTitle">
    <xsl:apply-templates select="/mycoreobject" mode="pageTitle"/>
  </xsl:variable>
  <xsl:param name="resultListEditorID"/>
  <xsl:param name="numPerPage"/>
  <xsl:param name="page"/>
  <xsl:param name="previousObject" />
  <xsl:param name="previousObjectHost" />
  <xsl:param name="nextObject" />
  <xsl:param name="nextObjectHost" />

  <xsl:template match="/mycoreobject" priority="0">
    <!-- Here put in dynamic resultlist -->
    <xsl:apply-templates select="." mode="parent" />
    <xsl:call-template name="resultsub" />
    <xsl:choose>
      <xsl:when test="mcracl:check-permission(/mycoreobject/@ID,'read')">
        <!-- if access granted: print metadata -->
        <xsl:apply-templates select="." mode="present"/>
        <!-- IE Fix for padding and border -->
        <hr/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="mcri18n:translate('metaData.accessDenied')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="/mycoreobject" mode="pageTitle" priority="0">
    <xsl:value-of select="mcri18n:translate('metaData.pageTitle')"/>
  </xsl:template>

  <xsl:template match="/mycoreobject" mode="parent" priority="0">
    <xsl:if test="./structure/parents">
      <div id="parent">
        <!-- Pay a little attention to this !!! -->
        <xsl:apply-templates select="./structure/parents">
          <xsl:with-param name="obj_type" select="'this'" />
        </xsl:apply-templates>
        &#160;&#160;
        <xsl:apply-templates select="./structure/parents">
          <xsl:with-param name="obj_type" select="'before'" />
        </xsl:apply-templates>
        &#160;&#160;
        <xsl:apply-templates select="./structure/parents">
          <xsl:with-param name="obj_type" select="'after'" />
        </xsl:apply-templates>
      </div>
    </xsl:if>
  </xsl:template>

  <xsl:template match="/mycoreobject" mode="present" priority="0">
    <xsl:variable name="objectType" select="substring-before(substring-after(@ID,'_'),'_')" />
    <xsl:value-of select="mcri18n:translate('metaData.noTemplate')"/>
    <form method="get" style="padding:20px;background-color:yellow">
      <fieldset>
        <legend>Automatisches Erzeugen von Vorlagen</legend>
        <table>
          <tr>
            <td>
              <label>Was erzeugen?</label>
            </td>
            <td>
              <select name="XSL.Style">
                <option value="generateMessages">messages_*.properties Vorlage</option>
                <option value="generateStylesheet">
                  <xsl:value-of select="concat($objectType,'.xsl Vorlage')" />
                </option>
              </select>
            </td>
          </tr>
        </table>
      </fieldset>
      <fieldset>
        <legend>
          <xsl:value-of select="concat('Optionen für Erzeugen von ',$objectType,'.xsl')" />
        </legend>
        <table>
          <tr>
            <td>
              <label>Objekt kann Derivate enthalten</label>
            </td>
            <td>
              <input type="checkbox" name="XSL.withDerivates" />
            </td>
          </tr>
          <tr>
            <td>
              <label>Unterstützung für IView</label>
            </td>
            <td>
              <input type="checkbox" name="XSL.useIView" />
            </td>
          </tr>
          <tr>
            <td>
              <label>Kindobjekttypen</label>
            </td>
            <td>
              <input name="XSL.childObjectTypes" />
              (durch Leerzeichen getrennt)
            </td>
          </tr>
        </table>
      </fieldset>
      <input type="submit" value="erstellen" />
    </form>
  </xsl:template>

  <!-- Generates a header for the metadata output -->
  <xsl:template name="resultsub">
    <table id="metaHeading" cellpadding="0" cellspacing="0">
      <tr>
        <td class="titles">
          <xsl:apply-templates select="." mode="title" />
        </td>
        <td class="browseCtrl">
          <xsl:call-template name="browseCtrl" />
        </td>
      </tr>
    </table>
    <!-- IE Fix for padding and border -->
    <hr />
  </xsl:template>

  <xsl:template name="browseCtrl">
    <xsl:if test="string-length($previousObject)>0">
      <a href="{$WebApplicationBaseURL}receive/{$previousObject}">&lt;&lt;</a>
      &#160;&#160;
    </xsl:if>
    <xsl:if test="string-length($numPerPage)>0">
      <a
        href="{$ServletsBaseURL}MCRSearchServlet?mode=results&amp;id={$resultListEditorID}&amp;page={$page}&amp;numPerPage={$numPerPage}">
        ^
    </a>
    </xsl:if>
    <xsl:if test="string-length($nextObject)>0">
      &#160;&#160;
      <a href="{$WebApplicationBaseURL}receive/{$nextObject}">&gt;&gt;</a>
    </xsl:if>
  </xsl:template>

  <xsl:template match="/mycoreobject" mode="title" priority="0">
    <xsl:value-of select="@ID" />
  </xsl:template>

  <xsl:template match="/mycoreobject" mode="resulttitle" priority="0">
    <xsl:value-of select="@ID" />
  </xsl:template>

  <!-- Internal link from Derivate ********************************* -->
  <xsl:template match="internals">
    <xsl:variable name="derivid" select="../../@ID" />
    <xsl:variable name="derivlabel" select="../../@label" />
    <xsl:variable name="derivmain" select="internal/@maindoc" />
    <xsl:variable name="derivbase" select="concat($ServletsBaseURL,'MCRFileNodeServlet/',$derivid,'/')" />
    <xsl:variable name="derivifs" select="concat($derivbase,$derivmain)" />
    <xsl:variable name="derivdir" select="$derivbase" />
    <xsl:variable name="derivxml" select="concat('ifs:/',$derivid)" />
    <xsl:variable name="details" select="document($derivxml)" />
    <xsl:variable name="ctype" select="$details/mcr_directory/children/child[name=$derivmain]/contentType" />
    <xsl:variable name="ftype" select="document('webapp:FileContentTypes.xml')/FileContentTypes/type[@ID=$ctype]/label" />
    <xsl:variable name="size" select="$details/mcr_directory/size" />
    <div class="derivateHeading">
      <xsl:choose>
        <xsl:when test="../titles">
          <xsl:variable name="currentLangNode" select="../titles/title[@xml:lang=$CurrentLang]"/>
          <xsl:variable name="defaultLangNode" select="../titles/title[@xml:lang=$DefaultLang]"/>
          <xsl:variable name="firstLangNode" select="../titles/title[1]"/>
          <xsl:choose>
            <xsl:when test="count($currentLangNode) = 0">
              <xsl:value-of select="$currentLangNode[1]"/>
            </xsl:when>
            <xsl:when test="count($defaultLangNode) = 0">
              <xsl:value-of select="$defaultLangNode[1]"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$firstLangNode[1]"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$derivlabel" />
        </xsl:otherwise>
      </xsl:choose>
    </div>
    <div class="derivate">
      <a href="{$derivifs}" target="_blank">
        <xsl:value-of select="$derivmain" />
      </a>
      (
      <xsl:value-of select="ceiling(number($size) div 1024)" />
      &#160;kB) &#160;&#160;
      <xsl:variable name="ziplink" select="concat($ServletsBaseURL,'MCRZipServlet','?id=',$derivid)" />
      <a class="linkButton" href="{$ziplink}">
        <xsl:value-of select="mcri18n:translate('buttons.zipGen')"/>
      </a>
      &#160;
      <a href="{$derivdir}">
        <xsl:value-of select="mcri18n:translate('buttons.details')"/>
      </a>
    </div>
  </xsl:template>

  <!-- External link from Derivate ********************************* -->
  <xsl:template match="externals">
    <div class="derivateHeading">
      <xsl:value-of select="mcri18n:translate('metaData.link')"/>
    </div>
    <div class="derivate">
      <xsl:call-template name="webLink">
        <xsl:with-param name="nodes" select="external" />
      </xsl:call-template>
    </div>
  </xsl:template>

  <!-- Link to the parent ****************************************** -->
  <xsl:template match="parents">
    <xsl:param name="obj_type" />
    <xsl:variable name="thisid">
      <xsl:value-of select="../../@ID" />
    </xsl:variable>
    <xsl:variable name="parent">
      <xsl:copy-of select="document(concat('mcrobject:',parent/@xlink:href))/mycoreobject" />
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$obj_type = 'this'">
        <xsl:call-template name="objectLink">
          <xsl:with-param name="obj_id" select="parent/@xlink:href" />
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$obj_type = 'before'">
        <xsl:variable name="pos">
          <xsl:for-each select="$parent/structure/children/child">
            <xsl:sort select="." />
            <xsl:variable name="child">
              <xsl:value-of select="@xlink:href" />
            </xsl:variable>
            <xsl:if test="$thisid = $child">
              <xsl:value-of select="position()" />
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="$parent/structure/children/child">
          <xsl:sort select="." />
          <xsl:variable name="child">
            <xsl:value-of select="@xlink:href" />
          </xsl:variable>
          <xsl:if test="position() = $pos - 1">
            <a href="{$WebApplicationBaseURL}receive/{$child}">
              &#60;--
            </a>
          </xsl:if>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="$obj_type = 'after'">
        <xsl:variable name="pos">
          <xsl:for-each select="$parent/structure/children/child">
            <xsl:sort select="." />
            <xsl:variable name="child">
              <xsl:value-of select="@xlink:href" />
            </xsl:variable>
            <xsl:if test="$thisid = $child">
              <xsl:value-of select="position()" />
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="$parent/structure/children/child">
          <xsl:sort select="." />
          <xsl:variable name="child">
            <xsl:value-of select="@xlink:href" />
          </xsl:variable>
          <xsl:if test="position() = $pos + 1">
            <a href="{$WebApplicationBaseURL}receive/{$child}">
              --&#62; </a>
          </xsl:if>
        </xsl:for-each>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Work with the children ************************************** -->
  <xsl:template match="children">
    <ul>
      <xsl:for-each select="child">
        <xsl:sort select="concat(@xlink:title,@xlink:label)" />
        <li>
          <xsl:apply-templates select="." />
        </li>
      </xsl:for-each>
    </ul>
  </xsl:template>

  <!-- Link to the child ******************************************* -->
  <xsl:template match="child">
    <xsl:call-template name="objectLink">
      <xsl:with-param name="obj_id" select="@xlink:href" />
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="mycoreobject" mode="versioninfo">
    <xsl:variable name="verinfo" select="document(concat('versioninfo:',@ID))" />
    <ol class="versioninfo">
      <xsl:for-each select="$verinfo/versions/version">
        <xsl:sort order="descending" select="position()" data-type="number" />
        <li>
          <xsl:if test="@r">
            <xsl:variable name="href">
              <xsl:value-of select="mcrurl:set-param($RequestURL,'r',@r)" />
            </xsl:variable>
            <span class="rev">
              <xsl:choose>
                <xsl:when test="@action='D'">
                  <xsl:value-of select="@r" />
                </xsl:when>
                <xsl:otherwise>
                  <a href="{$href}">
                    <xsl:value-of select="@r" />
                  </a>
                </xsl:otherwise>
              </xsl:choose>
            </span>
            <xsl:value-of select="' '" />
          </xsl:if>
          <xsl:if test="@action">
            <span class="action">
              <xsl:value-of select="mcri18n:translate(concat('metaData.versions.action.',@action))"/>
            </span>
            <xsl:value-of select="' '" />
          </xsl:if>
          <span class="@date">
            <xsl:value-of select="format-dateTime(@date, mcri18n:translate('metaData.date.xsl3'))"/>
          </span>
          <xsl:value-of select="' '" />
          <xsl:if test="@user">
            <span class="user">
              <xsl:value-of select="@user"/>
            </span>
            <xsl:value-of select="' '"/>
          </xsl:if>
        </li>
      </xsl:for-each>
    </ol>
  </xsl:template>

  <xsl:template name="objectLink">
    <!-- specify either one of them -->
    <xsl:param name="obj_id"/>
    <xsl:param name="mcrobj"/>
    <xsl:choose>
      <xsl:when test="$mcrobj">
        <xsl:variable name="obj_id" select="$mcrobj/@ID"/>
        <xsl:choose>
          <xsl:when test="mcracl:check-permission($obj_id,'read')">
            <a href="{$WebApplicationBaseURL}receive/{$obj_id}">
              <xsl:attribute name="title">
                <xsl:apply-templates select="$mcrobj" mode="fulltitle"/>
              </xsl:attribute>
              <xsl:apply-templates select="$mcrobj" mode="resulttitle"/>
            </a>
          </xsl:when>
          <xsl:otherwise>
            <!-- Build Login URL for LoginServlet -->
            <xsl:variable name="LoginURL"
                          select="concat( $ServletsBaseURL, 'MCRLoginServlet','?url=', encode-for-uri( string( $RequestURL ) ) )"/>
            <xsl:apply-templates select="$mcrobj" mode="resulttitle"/>
            &#160;
            <a href="{$LoginURL}">
              <img src="{concat($WebApplicationBaseURL,'images/paper_lock.gif')}"/>
            </a>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="string-length($obj_id)&gt;0">
        <!-- handle old way which may cause a double parsing of mcrobject: -->
        <xsl:variable name="mcrobj" select="document(concat('mcrobject:',$obj_id))/mycoreobject"/>
        <xsl:choose>
          <xsl:when test="mcracl:check-permission($obj_id,'read')">
            <a href="{$WebApplicationBaseURL}receive/{$obj_id}">
              <xsl:apply-templates select="$mcrobj" mode="resulttitle"/>
            </a>
          </xsl:when>
          <xsl:otherwise>
            <!-- Build Login URL for LoginServlet -->
            <xsl:variable name="LoginURL"
                          select="concat( $ServletsBaseURL, 'MCRLoginServlet','?url=', encode-for-uri( string( $RequestURL ) ) )"/>
            <xsl:apply-templates select="$mcrobj" mode="resulttitle"/>
            &#160;
            <a href="{$LoginURL}">
              <img src="{concat($WebApplicationBaseURL,'images/paper_lock.gif')}"/>
            </a>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="webLink">
    <xsl:param name="nodes" />
    <xsl:param name="next" />
    <xsl:for-each select="$nodes">
      <xsl:if test="position() != 1">
        <xsl:value-of select="$next" disable-output-escaping="yes" />
      </xsl:if>
      <xsl:variable name="href" select="@xlink:href" />
      <xsl:variable name="title">
        <xsl:choose>
          <xsl:when test="@xlink:title">
            <xsl:value-of select="@xlink:title" />
          </xsl:when>
          <xsl:when test="@xlink:label">
            <xsl:value-of select="@xlink:label" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@xlink:href" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <a href="{@xlink:href}">
        <xsl:value-of select="$title" />
      </a>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
