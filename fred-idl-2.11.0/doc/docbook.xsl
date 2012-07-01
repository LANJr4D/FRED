<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:db="http://www.w3.org/1999/XSL/Format"
                version='1.0'>

 <xsl:output method='xml'/>

 <!-- functions list template -->
 <xsl:template match='compounddef[@kind="interface"]'>
  <orderedlist>
   <xsl:apply-templates select='.//memberdef'/>
  </orderedlist>
 </xsl:template>

 <!-- function template -->
 <xsl:template match='memberdef[@kind="function"]'>
  <listitem>
   <formalpara>
    <title>
     <xsl:apply-templates select='definition'/>
     <xsl:apply-templates select='argsstring'/>
    </title>
    <xsl:element name='para'> 
     <xsl:element name='para'>
      <xsl:value-of select='briefdescription'/>
     </xsl:element>
     <xsl:element name='para'>
      <xsl:apply-templates select='detaileddescription/para/text()'/>
     </xsl:element>
     <xsl:apply-templates select='detaileddescription/para/parameterlist[@kind="param"]'/>
     <xsl:apply-templates select='detaileddescription/para/simplesect[@kind="return"]'/>
    </xsl:element>
   </formalpara>
  </listitem>
 </xsl:template>

 <xsl:template match='parameterlist[@kind="param"]'>
  <variablelist>
   <xsl:apply-templates select='parameteritem'/>
  </variablelist>  
 </xsl:template>

 <xsl:template match='parameteritem'>
  <varlistentry>
   <term>
    <xsl:apply-templates select='parameternamelist'/>
   </term>
   <listitem>
    <para><xsl:apply-templates select='parameterdescription'/></para>
   </listitem>
  </varlistentry>  
 </xsl:template>

 <xsl:template match='simplesect[@kind="return"]'>
  <variablelist>
   <varlistentry>
    <term>Návratová hodnota</term>
    <listitem>
     <para><xsl:apply-templates/></para>
    </listitem>
   </varlistentry>  
  </variablelist>
 </xsl:template>

</xsl:stylesheet>
