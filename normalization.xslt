<xsl:stylesheet version="1.0" 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <!--Normalize whitespace by stripping space and and indenting -->
  <xsl:output method="xml" version="1.0" indent="yes"/>
  <xsl:strip-space elements="*"/>	
  
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates>
        <xsl:sort select="name()"/>
        <xsl:sort select="."/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
    	
</xsl:stylesheet>
