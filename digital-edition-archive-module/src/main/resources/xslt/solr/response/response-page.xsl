<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mcri18n="http://www.mycore.de/xslt/i18n"
                exclude-result-prefixes="mcri18n xsl"
                version="3.0">

    <xsl:template match="/response/result|lst[@name='grouped']/lst[@name='returnId']" priority="10">
        <xsl:variable name="ResultPages">
            <xsl:if test="$hits &gt; 0">
                <xsl:call-template name="solr.Pagination">
                    <xsl:with-param name="size" select="$rows"/>
                    <xsl:with-param name="currentpage" select="$currentPage"/>
                    <xsl:with-param name="totalpage" select="$totalPages"/>
                    <xsl:with-param name="class" select="'pagination-sm'"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>

        <div class="row result_head">
            <div class="col-12 result_headline">
                <h1>
                    <small>
                        <xsl:choose>
                            <xsl:when test="$hits=0">
                                <xsl:value-of select="mcri18n:translate('results.noObject')"/>
                            </xsl:when>
                            <xsl:when test="$hits=1">
                                <xsl:value-of select="mcri18n:translate('results.oneObject')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="mcri18n:translate-with-params('results.nObjects',$hits)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </small>
                </h1>
            </div>
        </div>

        <!-- Pagination & Trefferliste -->
        <div class="row result_body">
            <div class="cols-xs-12 col-sm-8 col-lg-9 result_list">
                <div id="hit_list" class="list-group">
                    <xsl:apply-templates select="doc|arr[@name='groups']/lst/str[@name='groupValue']"/>
                </div>
                <xsl:copy-of select="$ResultPages"/>
            </div>

        </div>
    </xsl:template>

    <xsl:template match="doc" priority="10" mode="resultList">
        <xsl:param name="hitNumberOnPage" select="count(preceding-sibling::*[name()=name(.)])+1"/>
        <!--
          Do not read MyCoRe object at this time
        -->
        <xsl:variable name="identifier" select="@id"/>
        <xsl:variable name="mcrobj" select="."/>
        <xsl:variable name="hitItemClass">
            <xsl:choose>
                <xsl:when test="$hitNumberOnPage mod 2 = 1">odd</xsl:when>
                <xsl:otherwise>even</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- generate browsing url -->
        <xsl:variable name="href" select="concat($proxyBaseURL,$HttpSession,$solrParams)"/>
        <xsl:variable name="startPosition" select="$hitNumberOnPage - 1 + (($currentPage) -1) * $rows"/>
        <xsl:variable name="hitHref">
            <xsl:value-of
                    select="concat($href, '&amp;start=',$startPosition, '&amp;fl=id&amp;rows=1&amp;origrows=', $rows, '&amp;XSL.Style=browse')"/>
        </xsl:variable>

        <!-- hit entry -->
        <div class="list-group-item {$hitItemClass}">
            <div class="row">
                <div class="col-md-12">
                    <a href="{$hitHref}">
                        <xsl:choose>
                            <xsl:when test="./str[@name='objectType'] = 'tei'">
                                <xsl:value-of select="./arr[@name='digital-edition-archive.title']/str[1]"/>
                            </xsl:when>
                            <xsl:when test="./str[@name='objectType'] = 'edition'">
                                <xsl:value-of select="./arr[@name='digital-edition-archive.title']/str[1]"/>
                            </xsl:when>
                            <xsl:when test="./str[@name='objectType'] = 'bibl'">
                                <xsl:value-of select="./arr[@name='digital-edition-archive.title']/str[1]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="./arr[@name='digital-edition-archive.title']/str[1]"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </a>
                </div>
            </div>
        </div>
        <!--
        <div class="col-md-1">
          <xsl:value-of select="$hitNumberOnPage" />
        </div>
        <div class="col-md-9">
          <xsl:if test="./arr[@name='digital-edition-archive.title']/str[1]">
              <h4 style="margin-top:0px"><xsl:value-of select="./arr[@name='digital-edition-archive.title']/str[1]" /></h4>
          </xsl:if>
          <dl class="dl-horizontal">
            <dt><xsl:value-of select="mcri18n:translate('search.response.link')" /></dt>
            <dd>
              <a href="{$hitHref}">
                <xsl:attribute name="title"><xsl:value-of select="concat(mcri18n:translate('search.response.score'),' ', ./float[@name='score'])" /></xsl:attribute>
                <xsl:value-of select="$identifier" />
              </a>
            </dd>
            <dt><xsl:value-of select="mcri18n:translate('search.response.created')" /></dt>
            <dd>
              <xsl:value-of select="concat(./date[@name='created'], ' ', mcri18n:translate('search.response.created.by'),' ', ./str[@name='createdby'])" />
            </dd>
          </dl>
        </div>
      </div><end hit item -->
    </xsl:template>
</xsl:stylesheet>