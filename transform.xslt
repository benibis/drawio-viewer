<xsl:stylesheet version="1.0" 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <xsl:import href="normalization.xslt"/>
  
  <xsl:param name="ignore"/>

  <xsl:variable name="ignore2" 
       select="concat(normalize-space($ignore),',')"/>
  
  <xsl:template match="*">
    <xsl:if test="not(contains($ignore2,concat(name(),',')))">
      <xsl:apply-imports/>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>
