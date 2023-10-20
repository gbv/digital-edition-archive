<?xml version="1.0" encoding="utf-8"?>
<!-- ============================================== -->
<!-- $Revision$ $Date$ -->
<!-- ============================================== -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mcri18n="http://www.mycore.de/xslt/i18n"
                xmlns:mcrversion="http://www.mycore.de/xslt/mcrversion"
                xmlns:mcrlayoututils="http://www.mycore.de/xslt/layoututils"
                xmlns:mcrurl="http://www.mycore.de/xslt/url"
                exclude-result-prefixes="mcri18n mcrversion mcrlayoututils mcrurl"
                version="3.0">

    <xsl:include href="resource:xsl/default-parameters.xsl"/>
    <xsl:include href="xslInclude:functions"/>
    <xsl:include href="xslInclude:components-3"/>
    <xsl:include href="common-layout.xsl"/>

    <xsl:output method="html" indent="yes" omit-xml-declaration="yes"
                media-type="text/html"
                version="5"/>
    <xsl:strip-space elements="*"/>

    <!-- Various versions -->
    <xsl:variable name="bootstrap.version" select="'4.3.1'"/>
    <xsl:variable name="fontawesome.version" select="'5.10.1'"/>
    <xsl:variable name="jquery.version" select="'3.1.1'"/>
    <xsl:variable name="jquery.migrate.version" select="'1.4.1'"/>
    <!-- End of various versions -->
    <xsl:variable name="PageTitle" select="/*/@title"/>

    <xsl:template match="/site">
        <html lang="{$CurrentLang}" class="no-js">
            <head>
                <meta charset="utf-8"/>
                <title>
                    <xsl:value-of select="$PageTitle"/>
                </title>
                <xsl:comment>
                    Mobile viewport optimization
                </xsl:comment>
                <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

                <link href="{$WebApplicationBaseURL}webjars/font-awesome/{$fontawesome.version}/css/all.min.css"
                      rel="stylesheet"/>
                <link href="{$WebApplicationBaseURL}rsc/sass/scss/bootstrap-digital-edition-archive.css"
                      rel="stylesheet"/>
                <script type="text/javascript"
                        src="{$WebApplicationBaseURL}webjars/jquery/{$jquery.version}/jquery.min.js"></script>
                <script type="text/javascript"
                        src="{$WebApplicationBaseURL}webjars/jquery-migrate/{$jquery.migrate.version}/jquery-migrate.min.js"></script>

                <xsl:copy-of select="head/*"/>
            </head>

            <body>

                <header class="bg-primary">
                    <xsl:call-template name="navigation"/>
                </header>

                <section class="container my-5" id="page">
                    <xsl:variable name="readAccess"
                                  select="mcrlayoututils:read-access(mcrurl:delete-session($RequestURL), '')"/>
                    <xsl:choose>
                        <xsl:when test="$readAccess='true'">
                            <xsl:copy-of select="*[not(name()='head')]"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="printNotLoggedIn"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </section>

                <footer class="panel-footer bg-primary" role="contentinfo">
                    <div class="container p-5">
                        <div class="row">
                            <div class="col-6">
                                <ul class="nav">
                                    <xsl:apply-templates select="$loaded_navigation_xml/menu[@id='brand']/*"/>
                                </ul>
                            </div>

                            <div class="col-6">
                                <xsl:variable name="mcr_version"
                                              select="concat('MyCoRe ', mcrversion:get-complete-version())"/>
                                <div id="powered_by" class="text-center">
                                    <a href="http://www.mycore.de">
                                        <img src="{$WebApplicationBaseURL}content/images/mycore_logo_small_invert.png"
                                             title="{$mcr_version}" alt="powered by MyCoRe"/>
                                    </a>
                                </div>
                            </div>
                        </div>

                    </div>
                </footer>


                <script type="text/javascript">
                    <!-- Bootstrap & Query-Ui button conflict workaround  -->
                    if (jQuery.fn.button){jQuery.fn.btn = jQuery.fn.button.noConflict();}
                </script>
                <script type="text/javascript"
                        src="{$WebApplicationBaseURL}webjars/bootstrap/{$bootstrap.version}/js/bootstrap.bundle.min.js"></script>
                <script>

                    $(document).ready(function(){
                    $('[data-toggle="tooltip"]').tooltip();
                    });

                    $( document ).ready(function() {
                    $('.overtext').tooltip();
                    $.confirm.options = {
                    text: "<xsl:value-of select="mcri18n:translate('confirm.text')"/>",
                    title: "<xsl:value-of select="mcri18n:translate('confirm.title')"/>",
                    confirmButton: "<xsl:value-of select="mcri18n:translate('confirm.confirmButton')"/>",
                    cancelButton: "<xsl:value-of select="mcri18n:translate('confirm.cancelButton')"/>",
                    post: false
                    }
                    });
                </script>
            </body>
        </html>
    </xsl:template>


    <!-- create navigation -->
    <xsl:template name="navigation">

        <div id="header_box" class="clearfix container">
            <div style="font-size:200%;margin:6px" id="project_logo_box">
                <a href="{concat($WebApplicationBaseURL,substring($loaded_navigation_xml/@hrefStartingPage,2),$HttpSession)}">
                    Digitales Text-Archiv
                </a>
            </div>
        </div>

        <!-- Collect the nav links, forms, and other content for toggling -->
        <div class="navbar navbar-expand-lg">
            <div class="container">

                <div class="navbar-brand">
                    <button class="navbar-toggler" type="button" data-toggle="collapse" data-target=".main-nav-entries">
                        <span class="navbar-toggler-icon"></span>
                    </button>
                </div>

                <div class="main-nav-entries collapse navbar-collapse">
                    <ul class="navbar-nav">
                        <xsl:apply-templates select="$loaded_navigation_xml/menu[@id='search']"/>
                        <xsl:apply-templates select="$loaded_navigation_xml/menu[@id='browse']"/>
                        <xsl:apply-templates select="$loaded_navigation_xml/menu[@id='publish']"/>
                    </ul>
                    <ul class="navbar-nav ml-auto">
                        <xsl:call-template name="loginMenu"/>
                        <xsl:call-template name="languageMenu"/>
                    </ul>
                </div>

                <form action="{$WebApplicationBaseURL}servlets/solr/select" method="get" class="form-inline my-2 my-lg-0"
                      role="search" id="mainSearch">
                    <div class="form-group">
                        <input name="q" placeholder="Suche" class="form-control mr-sm-2 search-query"
                               id="searchInput"
                               type="text"
                        />
                        <input name="fq" type="hidden" value="objectKind:mycoreobject" />
                    </div>
                    <button type="submit" class="btn btn-primary my-2 my-sm-0">
                        <i class="fa fa-search"></i>
                    </button>
                </form>
                <script>
                    window.addEventListener('load', function () {
                       document.getElementById('mainSearch').addEventListener('submit', function (event) {
                           var searchInput = document.getElementById('searchInput');
                           if (searchInput.value === '') {
                               event.preventDefault();
                               searchInput.focus();
                           }
                       }); 
                    });
                </script>

            </div><!-- /container -->
        </div>
    </xsl:template>

</xsl:stylesheet>