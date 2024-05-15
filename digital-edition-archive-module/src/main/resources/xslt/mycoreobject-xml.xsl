<?xml version="1.0" encoding="UTF-8"?>

<!-- ============================================== -->
<!-- $Revision: 1.2 $ $Date: 2007-02-21 12:14:30 $ -->
<!-- ============================================== -->

<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:mcracl="http://www.mycore.de/xslt/acl"
                exclude-result-prefixes="mcracl xlink"
>

  <xsl:output method="xml" encoding="UTF-8" />
  <xsl:mode on-no-match="shallow-copy"/>
  <xsl:include href="default-parameters.xsl" />
  <xsl:include href="xslInclude:functions" />
  <xsl:include href="xslInclude:mycoreobjectXML-3" />

  <xsl:template match="mycoreobject">
    <xsl:copy>
      <xsl:apply-templates select="@*" />
	<!-- check the READ permission -->
      <xsl:if test="mcracl:check-permission(@ID,'read')">
        <xsl:apply-templates select="node()" />
      </xsl:if>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
