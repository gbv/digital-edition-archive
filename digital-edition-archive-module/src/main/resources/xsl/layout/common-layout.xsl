<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mcri18n="http://www.mycore.de/xslt/i18n"
                xmlns:mcrstring="http://www.mycore.de/xslt/stringutils"
                xmlns:mcrproperty="http://www.mycore.de/xslt/property"
                xmlns:mcrurl="http://www.mycore.de/xslt/url"
                xmlns:mcrlayoututils="http://www.mycore.de/xslt/layoututils"
                exclude-result-prefixes="mcri18n mcrstring mcrproperty mcrurl"
                version="3.0">
  <xsl:strip-space elements="*"/>

  <xsl:param name="numPerPage"/>
  <xsl:param name="previousObject"/>
  <xsl:param name="previousObjectHost"/>
  <xsl:param name="nextObject"/>
  <xsl:param name="nextObjectHost"/>
  <xsl:param name="resultListEditorID"/>
  <xsl:param name="page"/>
  <xsl:param name="breadCrumb"/>

  <xsl:variable name="loaded_navigation_xml" select="mcrlayoututils:get-personal-navigation()/navigation"/>
  <xsl:variable name="browserAddress" select="$RequestURL" />

  <!-- ========== create login menu for current user ================================ -->

  <xsl:template name="loginMenu">
    <xsl:variable name="loginURL"
                  select="concat( $ServletsBaseURL, 'MCRLoginServlet',$HttpSession,'?url=', encode-for-uri( string( $RequestURL ) ) )"/>
    <xsl:variable name="currentUserInfo" select="document('currentUserInfo:attribute=realName')"/>
    <xsl:choose>
      <xsl:when test="$currentUserInfo/user/@id=mcrproperty:one('MCR.Users.Guestuser.UserName')">
        <li class="nav-item">
          <a id="loginURL" class="nav-link" href="{$loginURL}">
            <xsl:value-of select="mcri18n:translate('component.userlogin.button.login')"/>
          </a>
        </li>
      </xsl:when>
      <xsl:otherwise>
        <li class="nav-item dropdown">
          <xsl:if test="$loaded_navigation_xml/menu[@id='user']//item[@href = $browserAddress ]">
            <xsl:attribute name="class">
              <xsl:value-of select="'active'"/>
            </xsl:attribute>
          </xsl:if>
          <a id="currentUser" class="nav-link dropdown-toggle" data-toggle="dropdown" href="#">
            <xsl:choose>
              <xsl:when test="count($currentUserInfo/user/attribute[@name='realName'])&gt;0 and string-length(currentUserInfo/user/attribute[@name='realName'][0]) &gt;0">
                <xsl:value-of select="$currentUserInfo/user/attribute[@name='realName']"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$currentUserInfo/user/@id"/>
              </xsl:otherwise>
            </xsl:choose>
          </a>
          <ul class="dropdown-menu dropdown-menu-right" role="menu" aria-labelledby="dLabel">
            <xsl:apply-templates select="$loaded_navigation_xml/menu[@id='user']/*"/>
          </ul>
        </li>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- ========== Check if given document has <site /> root tag ======================== -->
  <xsl:template match="/*[not(local-name()='site')]">
    <xsl:message terminate="yes">This is not a site document, fix your properties.</xsl:message>
  </xsl:template>


  <!-- ========== Check if current user has read access and show content if true ======= -->
  <xsl:template name="write.content">
        <xsl:apply-templates/>
  </xsl:template>


  <!-- ========== Create navigation for current user =================================== -->

  <xsl:template match="/navigation//label">
  </xsl:template>
  <xsl:template match="/navigation//menu[@id and (group[item] or item)]">
    <xsl:param name="active" select="descendant-or-self::item[@href = $browserAddress ]"/>
    <xsl:variable name="menuId" select="generate-id(.)"/>
    <li>
      <xsl:attribute name="class">
        <xsl:if test="$active">
          <xsl:value-of select="'active '"/>
        </xsl:if>
        <xsl:text>nav-item dropdown</xsl:text>
      </xsl:attribute>

      <a id="{$menuId}" class="nav-link dropdown-toggle" data-toggle="dropdown" href="#">
        <xsl:apply-templates select="." mode="linkText"/>
      </a>
      <ul class="dropdown-menu" role="menu" aria-labelledby="{$menuId}">
        <xsl:apply-templates select="item|group"/>
      </ul>
    </li>
  </xsl:template>
  <xsl:template match="/navigation//group[@id and item]">
    <xsl:param name="rootNode" select="."/>
    <xsl:if test="name(preceding-sibling::*[1])='item'">
      <li role="presentation" class="divider"/>
    </xsl:if>
    <xsl:if test="label">
      <li role="presentation" class="dropdown-header">
        <xsl:apply-templates select="." mode="linkText"/>
      </li>
    </xsl:if>
    <xsl:apply-templates/>
    <li role="presentation" class="divider"/>
  </xsl:template>

  <xsl:template match="/navigation//item[@href]">
    <xsl:param name="active" select="descendant-or-self::item[@href = $browserAddress ]"/>
    <xsl:param name="url">
      <xsl:choose>
        <!-- item @type is "intern" -> add the web application path before the link -->
        <xsl:when
            test=" starts-with(@href,'http:') or starts-with(@href,'https:') or starts-with(@href,'mailto:') or starts-with(@href,'ftp:')">
          <xsl:value-of select="@href"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="mcrurl:add-session(concat($WebApplicationBaseURL,substring-after(@href,'/')))" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <xsl:choose>
      <xsl:when test="string-length($url ) &gt; 0">
        <li>
          <xsl:attribute name="class">
            <xsl:if test="$active">
              <xsl:value-of select="'active '"/>
            </xsl:if>
            <xsl:text>nav-item</xsl:text>
          </xsl:attribute>
          <a href="{$url}" class="nav-link">
            <xsl:apply-templates select="." mode="linkText"/>
          </a>
        </li>
      </xsl:when>
      <xsl:otherwise>
        <xsl:comment>
          <xsl:apply-templates select="." mode="linkText"/>
        </xsl:comment>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="/navigation//*[label]" mode="linkText">
    <xsl:choose>
      <xsl:when test="label[lang($CurrentLang)] != ''">
        <xsl:value-of select="label[lang($CurrentLang)]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="label[lang($DefaultLang)]"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="printNotLoggedIn">
    <div class="alert alert-danger">
      <xsl:value-of select="mcri18n:translate('webpage.notLoggedIn')" disable-output-escaping="yes" />
    </div>
  </xsl:template>

  <xsl:template name="languageMenu">
    <li class="nav-item dropdown">
      <a class="nav-link dropdown-toggle" href="#" data-toggle="dropdown" title="{mcri18n:translate('language.change')}">
        <xsl:value-of select="mcri18n:translate(concat('language.change.', $CurrentLang))"/>
      </a>
      <ul class="dropdown-menu language-menu" role="menu">
        <xsl:for-each select="tokenize(mcrproperty:one('MCR.Metadata.Languages'), ',')">
          <xsl:variable name="lang">
            <xsl:value-of select="mcrstring:trim(.)"/>
          </xsl:variable>
          <xsl:if test="$lang!='' and $CurrentLang!=$lang">
            <li class="nav-item">
              <xsl:variable name="langURL">
                <xsl:call-template name="languageLink">
                  <xsl:with-param name="lang" select="$lang"/>
                </xsl:call-template>
              </xsl:variable>
              <a class="nav-link" href="{$langURL}" title="{mcri18n:translate(concat('language.', $lang))}">
                <xsl:value-of select="mcri18n:translate(concat('language.change.', $lang))"/>
              </a>
            </li>
          </xsl:if>
        </xsl:for-each>
      </ul>
    </li>
  </xsl:template>
  <xsl:template name="languageLink">
    <xsl:param name="lang"/>
    <xsl:variable name="langURL" select="mcrurl:set-param($RequestURL,'lang',$lang)" />
    <xsl:value-of select="mcrurl:add-session($langURL)" />
  </xsl:template>


</xsl:stylesheet>
