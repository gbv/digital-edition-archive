<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:mcri18n="http://www.mycore.de/xslt/i18n"
  xmlns:mcracl="http://www.mycore.de/xslt/acl"
  xmlns:mcrderivate="http://www.mycore.de/xslt/derivate"
  xmlns:mcrstring="http://www.mycore.de/xslt/stringutils"
  xmlns:mcrproperty="http://www.mycore.de/xslt/property"
  xmlns:mcriview2="http://www.mycore.de/xslt/iview2"
  exclude-result-prefixes="xlink mcri18n mcracl mcrderivate mcrstring mcrproperty mcriview2">
  
  <xsl:param name="MCR.Users.Superuser.UserName" />
  <xsl:param name="MCR.URN.Resolver.MasterURL" select="''" />

  <xsl:template match="/mycoreobject">
    <xsl:call-template name="mycoreobject_head" />


      <xsl:call-template name="objectActions" />

      <xsl:apply-templates select="." mode="frontpage" />

  </xsl:template>
  
  <xsl:template name="mycoreobject_head">
    <head>
      <link href="{$WebApplicationBaseURL}css/file.css" rel="stylesheet" />
  
      <script src="{$WebApplicationBaseURL}modules/webtools/upload/js/upload-api.js"></script>
      <script src="{$WebApplicationBaseURL}modules/webtools/upload/js/upload-gui.js"></script>
      
      <link rel="stylesheet" type="text/css" href="{$WebApplicationBaseURL}modules/webtools/upload/css/upload-gui.css" />
      
      <script>
        window["mycoreUploadSettings"] = {
          webAppBaseURL:"<xsl:value-of select='$WebApplicationBaseURL' />"
        }
      </script>
    </head>
  </xsl:template>

  <!-- show derivates if available and CurrentUser has read access -->
  <xsl:template name="showDerivates">

    <xsl:if test="structure/derobjects/derobject[mcracl:check-permission(@xlink:href,'read')]">
        <xsl:apply-templates select="structure/derobjects/derobject[mcracl:check-permission(@xlink:href,'read')]">
          <xsl:with-param name="objID" select="@ID" />
        </xsl:apply-templates>
    </xsl:if>
    
    <xsl:if test="mcracl:check-permission(@ID,'writedb')">
      <div id="mcr-file-upload-{@ID}" class="file-upload-box well collapse" data-upload-object="{@ID}" data-upload-target="/">
        <i class="fa fa-upload" style="float:left;font-size:333%;margin-right:0.5em"></i>
        <h4 style="margin-top:0px">
          <xsl:value-of select="concat(' ', mcri18n:translate('fileupload.drop.headline.new-derivate'))" />
        </h4>
        <xsl:copy-of
          select="parse-xml-fragment(concat(' ', mcri18n:translate('fileupload.drop.upload-file')))" />
      </div>
  
      <script>
        $(document).ready(function() {
            $('.file-upload-box').each(function(index, element) {
                mycore.upload.enable(element.parentElement);
            });
            $('.file-upload-box').on('show.bs.collapse', function() {
                var current = this;
                $('.file-upload-box').each(function(index, element) {
                    if (this != current) {
                        $(this).collapse('hide');
                    }
                });
            });
            $('.file-upload-box').on('shown.bs.collapse', function() {
                if (!$(this).attr('id').contains("_derivate_")) {
                    this.scrollIntoView();
                }
            });
        });
      </script> 
    </xsl:if>
  </xsl:template>

  <xsl:template name="objectActions">
    <xsl:param name="id" select="./@ID" />
    <xsl:param name="objectType" select="substring-before(substring-after(@ID,'_'),'_')" />
    <xsl:param name="accessedit" select="mcracl:check-permission($id,'writedb')" />
    <xsl:param name="accessdelete" select="mcracl:check-permission($id,'deletedb')" />

    <xsl:if test="$accessedit or $accessdelete">
      <div class="dropdown float-right">
        <button class="btn btn-secondary dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">
          <span class="fa fa-cog" aria-hidden="true"></span> Aktionen
          <span class="caret"></span>
        </button>
        <div class="dropdown-menu" role="menu" aria-labelledby="dropdownMenu1">
          <a class="dropdown-item" tabindex="-1"
             href="{$WebApplicationBaseURL}content/publish/{$objectType}.xed?id={$id}">
            <xsl:value-of select="mcri18n:translate('object.editObject')"/>
          </a>
          <!--
          <a href="{$ServletsBaseURL}derivate/create{$HttpSession}?id={$id}" role="menuitem" tabindex="-1">
            <xsl:value-of select="mcri18n:translate('derivate.addDerivate')" />
          </a>
          -->
          <a class="dropdown-item" href="#mcr-file-upload-{@ID}" role="menuitem" data-toggle="collapse" tabindex="-1">
            <xsl:value-of select="mcri18n:translate('derivate.addDerivate')"/>
          </a>

          <xsl:if test="$accessdelete">
            <a class="dropdown-item" href="{$ServletsBaseURL}object/delete{$HttpSession}?id={$id}" role="menuitem"
               tabindex="-1">
              <xsl:value-of select="mcri18n:translate('object.delObject')"/>
            </a>
          </xsl:if>
        </div>
      </div>

    </xsl:if>

  </xsl:template>


  <xsl:template match="derobject">
    <xsl:param name="objID" />
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
              <div class="row">
                <div class="col-12">
                  <div data-viewer="{$viewerID}" style="min-height:500px; position:relative;">
                  </div>
                </div>
              </div>
              <script src="{$WebApplicationBaseURL}rsc/viewer/{$derId}/{$mainFile}?embedded=true&amp;XSL.Style=js">
              </script>
            </xsl:when>
            <xsl:otherwise>
              <div class="card card-body bg-light no-viewer">
                <xsl:value-of select="mcri18n:translate-with-params('metaData.previewInProcessing', $derId)" />
              </div>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
      </xsl:choose>
    </xsl:if>


    <div id="mcr-files-{@xlink:href}" class="file_box">
      <div class="row header">
        <div class="col-12">
          <div class="headline">
            <div class="title">
              <a class="btn btn-primary btn-sm file_toggle" data-toggle="collapse" href="#mcr-collapse-{@xlink:href}" aria-expanded="false" aria-controls="collapse{@xlink:href}">
                <span>
                  <xsl:choose>
                    <!-- <xsl:when test="$derivateXML//titles/title[@xml:lang=$CurrentLang]">
                      <xsl:value-of select="$derivateXML//titles/title[@xml:lang=$CurrentLang]" />
                    </xsl:when> -->
                    <xsl:when test="not(starts-with(@xlink:title,'data object from'))">
                      <xsl:value-of select="@xlink:title" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="mcri18n:translate('metadata.derivates.files')" />
                      <xsl:if test="position() > 1">
                          <span class="set_number">
                            <xsl:value-of select="position()" />
                          </span>
                      </xsl:if>
                    </xsl:otherwise>
                  </xsl:choose>
                </span>

                <span class="caret"></span>
              </a>
            </div>
            <xsl:apply-templates select="." mode="derivateActions">
              <xsl:with-param name="deriv" select="@xlink:href" />
              <xsl:with-param name="parentObjID" select="$objID" />
            </xsl:apply-templates>
            <div class="clearfix" />
          </div>
        </div>
      </div>

      <div id="mcr-collapse-{@xlink:href}" class="row body collapse show">
        <xsl:variable name="ifsDirectory" select="document(concat('ifs:',$derId,'/'))" />
        <xsl:variable name="numOfFiles" select="count($ifsDirectory/mcr_directory/children/child)" />
        <xsl:variable name="maindoc" select="$derivateXML/mycorederivate/derivate/internals/internal/@maindoc" />
        <xsl:variable name="path" select="$ifsDirectory/mcr_directory/path" />
		
		<xsl:if test="mcracl:check-permission($derId,'writedb')">
  		 <div id="mcr-file-upload-{$derId}" class="file-upload-box well well-sm collapse col-10 col-offset-1" style="margin-top:1em" data-upload-object="{$derId}" data-upload-target="/">
           <i class="fa fa-upload" style="float:left;font-size:275%;margin-right:0.5em"></i>
  		   <h5 style="margin-top:0px"><strong><xsl:value-of select="concat(' ', mcri18n:translate('fileupload.drop.headline.new-file'))"/></strong></h5>
           <xsl:copy-of select="parse-xml-fragment(concat(' ', mcri18n:translate('fileupload.drop.upload-file')))"/>
         </div>
		</xsl:if>
        <xsl:for-each select="$ifsDirectory/mcr_directory/children/child">
          <xsl:variable name="fileNameExt" select="concat($path,./name)" />
          <xsl:apply-templates select="." >
            <xsl:with-param name="derId"><xsl:value-of select="$derId" /></xsl:with-param>
            <xsl:with-param name="objID"><xsl:value-of select="$objID" /></xsl:with-param>
            <xsl:with-param name="maindoc"><xsl:value-of select="$maindoc" /></xsl:with-param>
          </xsl:apply-templates>
        </xsl:for-each>
      </div>
    </div>
  </xsl:template>


  <xsl:template match="child[@type='directory']" >
    <xsl:param name="derId" />
    <xsl:param name="objID" />
    <xsl:param name="maindoc" />


    <xsl:apply-templates select="." mode="childWriter">
      <xsl:with-param name="derId"><xsl:value-of select="$derId" /></xsl:with-param>
      <xsl:with-param name="objID"><xsl:value-of select="$objID" /></xsl:with-param>
      <xsl:with-param name="maindoc"><xsl:value-of select="$maindoc" /></xsl:with-param>
    </xsl:apply-templates>

    <xsl:variable name="dirName" select="./name" />
    <xsl:variable name="directory" select="document(concat('ifs:',$derId,'/',encode-for-uri($dirName)))" />
    <xsl:for-each select="$directory/mcr_directory/children/child">
      <xsl:apply-templates select="." mode="childWriter">
        <xsl:with-param name="derId"><xsl:value-of select="$derId" /></xsl:with-param>
        <xsl:with-param name="objID"><xsl:value-of select="$objID" /></xsl:with-param>
        <xsl:with-param name="maindoc"><xsl:value-of select="$maindoc" /></xsl:with-param>
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="child[@type='file']">
    <xsl:param name="derId" />
    <xsl:param name="objID" />
    <xsl:param name="maindoc" />

    <xsl:apply-templates select="." mode="childWriter">
      <xsl:with-param name="derId"><xsl:value-of select="$derId" /></xsl:with-param>
      <xsl:with-param name="objID"><xsl:value-of select="$objID" /></xsl:with-param>
      <xsl:with-param name="maindoc"><xsl:value-of select="$maindoc" /></xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="child" mode="childWriter">
    <xsl:param name="derId" />
    <xsl:param name="objID" />
    <xsl:param name="maindoc" />

    <xsl:variable name="path" select="../../path" />
    <xsl:variable name="fileName" >
      <xsl:choose>
        <xsl:when test="$path != '/' and $path != ''">
          <xsl:value-of select="substring(concat($path,./name),2)" ></xsl:value-of>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="./name" ></xsl:value-of>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="filePath" select="concat($derId,'/',encode-for-uri($fileName),$HttpSession)" />
    <xsl:variable name="fileCss">
      <xsl:choose>
        <xsl:when test="$maindoc = $fileName">
          <xsl:text>active_file</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>file</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <div class="col-12">
      <div class="file_set {$fileCss}">
        <xsl:if test="(mcracl:check-permission($derId,'writedb') or mcracl:check-permission($derId,'deletedb'))">
          <div class="options float-right">
            <div class="btn-group">
              <a href="#" class="btn btn-default dropdown-toggle" data-toggle="dropdown">
                <i class="fa fa-cog"></i>
                <span class="caret"></span>
              </a>
              <ul class="dropdown-menu dropdown-menu-right">
                <xsl:if test="mcracl:check-permission($derId,'writedb') and @type!='directory'">
                  <li class="dropdown-item">
                    <a title="{mcri18n:translate('IFS.mainFile')}"
                      href="{$WebApplicationBaseURL}servlets/MCRDerivateServlet{$HttpSession}?derivateid={$derId}&amp;objectid={$objID}&amp;todo=ssetfile&amp;file={$fileName}"
                      class="option" >
                      <span class="fa fa-star"></span>
                      <xsl:value-of select="mcri18n:translate('IFS.mainFile')" />
                    </a>
                  </li>
                </xsl:if>
                <xsl:if test="mcracl:check-permission($derId,'deletedb')">
                  <li class="dropdown-item">
                    <a href="{$WebApplicationBaseURL}servlets/MCRDerivateServlet{$HttpSession}?derivateid={$derId}&amp;objectid={$objID}&amp;todo=sdelfile&amp;file={$fileName}"
                      class="option confirm_deletion">
                      <xsl:attribute name="data-text">
                        <xsl:value-of select="mcri18n:translate(concat('mir.confirm.',@type,'.text'))" />
                      </xsl:attribute>
                      <xsl:attribute name="title">
                        <xsl:value-of select="mcri18n:translate(concat('IFS.',@type,'Delete'))" />
                      </xsl:attribute>
                      <span class="fa fa-trash"></span>
                      <xsl:value-of select="mcri18n:translate(concat('IFS.',@type,'Delete'))" />
                    </a>
                  </li>
                </xsl:if>
              </ul>
            </div>
          </div>
        </xsl:if>
        <span class="file_size">
          <xsl:text>[ </xsl:text>
          <xsl:value-of select="mcrstring:pretty-filesize(size)" />
          <xsl:text> ]</xsl:text>
        </span>


        <span class="file_date">
          <xsl:value-of select="format-dateTime(date[@type='lastModified'], mcri18n:translate('metaData.date.xsl3'))" />
        </span>
        <span class="file_name">
          <xsl:choose>
            <xsl:when test="@type!='directory'" >
             <a>
               <xsl:attribute name="href" >
                 <xsl:value-of select="concat($ServletsBaseURL,'MCRFileNodeServlet/',$filePath)" />
               </xsl:attribute>
               <xsl:value-of select="$fileName" />
             </a>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$fileName" />
            </xsl:otherwise>
          </xsl:choose>
        </span>
        <xsl:if test="concat($derId,'/',$maindoc) = $filePath">
        	<span class="{$fileCss} fa fa-star" style="margin-left:10px"></span>
        </xsl:if>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="derobject" mode="derivateActions">
    <xsl:param name="deriv" />
    <xsl:param name="parentObjID" />
    <xsl:param name="suffix" select="''" />

    <xsl:if test="mcracl:check-permission($deriv,'writedb')">
      <xsl:variable select="concat('mcrobject:',$deriv)" name="derivlink" />
      <xsl:variable select="document($derivlink)" name="derivate" />
   

      <div class="options float-right">
        <div class="btn-group">
          <a href="#" class="btn btn-default dropdown-toggle" data-toggle="dropdown">
            <i class="fa fa-cog"></i>
            <xsl:value-of select="' Aktionen'" />
            <span class="caret"></span>
          </a>
          <ul class="dropdown-menu dropdown-menu-right">
            <li class="dropdown-item">
              <a href="#mcr-file-upload-{$deriv}" class="option" data-toggle="collapse">
                <xsl:value-of select="mcri18n:translate('component.mods.metaData.options.addFile')" />
              </a>
            </li>
            <li class="dropdown-item">
              <a href="{$WebApplicationBaseURL}content/publish/derivate-label.xed?derivateid={$deriv}&amp;objectid={$parentObjID}{$HttpSession}">
                <xsl:value-of select="mcri18n:translate('component.mods.metaData.options.updateDerivateName')" />
              </a>
            </li>
            <xsl:if test="mcracl:check-permission($deriv,'deletedb')">
              <li class="dropdown-item last">
                <a href="{$ServletsBaseURL}derivate/delete{$HttpSession}?id={$deriv}" class="confirm_deletion option" data-text="{mcri18n:translate('mir.confirm.derivate.text')}">
                  <xsl:value-of select="mcri18n:translate('component.mods.metaData.options.delDerivate')" />
                </a>
              </li>
            </xsl:if>
          </ul>
        </div>
      </div>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
