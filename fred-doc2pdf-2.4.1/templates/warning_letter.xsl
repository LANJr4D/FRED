<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
<!ENTITY SPACE "<xsl:text xmlns:xsl='http://www.w3.org/1999/XSL/Transform'> </xsl:text>">
]>
<!-- 
 Generate RML document containing letters with warning about domain expiration
 in czech and english version for each domain and final summary table for
 czech post office.
 
 Input of this XSL stylesheet is XML document with a list of domains and 
 domains details. Sample of input document:
 <messages>
  <holder>
    <name><![CDATA[Pepa Zdepa]]></name>
    <street><![CDATA[Ulice]]></street>
    <city><![CDATA[Praha]]></city>
    <zip><![CDATA[12300]]></zip>
    <country><![CDATA[CZECH REPUBLIC]]></country>
    <expiring_domain>
      <domain><![CDATA[5.7.2.2.0.2.4.e164.arpa]]></domain>
      <registrar><![CDATA[Company l.t.d. (www.nic.cz)]]></registrar>
      <actual_date><![CDATA[2010-05-11]]></actual_date>
      <termination_date><![CDATA[2011-06-11 00:00:00]]></termination_date>
    </expiring_domain>
  </holder>
  <holder>
    <name><![CDATA[Pepa Zdepa]]></name>
    <street><![CDATA[Ulice]]></street>
    <city><![CDATA[Praha]]></city>
    <zip><![CDATA[12300]]></zip>
    <country><![CDATA[CZECH REPUBLIC]]></country>
    <expiring_domain>
      <domain><![CDATA[tmp535521.cz]]></domain>
      <registrar><![CDATA[Company l.t.d. (www.nic.cz)]]></registrar>
      <actual_date><![CDATA[2010-05-11]]></actual_date>
      <termination_date><![CDATA[2011-06-11 00:00:00]]></termination_date>
    </expiring_domain>
    <expiring_domain>
      <domain><![CDATA[tmp691334.cz]]></domain>
      <registrar><![CDATA[Company l.t.d. (www.nic.cz)]]></registrar>
      <actual_date><![CDATA[2010-05-11]]></actual_date>
      <termination_date><![CDATA[2011-06-11 00:00:00]]></termination_date>
    </expiring_domain>
  </holder>
 </messages>
 
 Resulting RML can be processed by doc2pdf to generate PDF version of letter 
 -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" encoding="utf-8"/>
  <xsl:include href="shared_templates.xsl"/>
  <xsl:variable name="lang01" select="'cs'"/>
  <xsl:variable name="lang02" select="'en'"/>
  <xsl:param name="lang" select="$lang01"/>
  <xsl:param name="srcpath" select="'templates/'" />
  <!-- this is very fragile and depends on whole formatting of the document - we must be sure that the table fits within the actual page, otherwise it has to be placed on the extra pages -->
  <xsl:param name="listlimit" select="2"/>
  <xsl:variable name="loc" select="document(concat('translation_', $lang, '.xml'))/strings"></xsl:variable>
  <!-- root template for rml document generation -->

  <xsl:template match="messages">
    <document>
      <template pageSize="(21cm, 29.7cm)" leftMargin="2.0cm" rightMargin="2.0cm" topMargin="2.0cm" bottomMargin="2.0cm" title="Extension of registration" showBoundary="0">
        <xsl:attribute name="author">
              <xsl:value-of select="$loc/str[@name='NIC_author']"/>
        </xsl:attribute>

        <xsl:call-template name="letterTemplate">
          <xsl:with-param name="lang" select="$lang01"/>
          <xsl:with-param name="templateName" select="concat('main_', $lang01)"/>
        </xsl:call-template>

        <xsl:call-template name="letterTemplate">
          <xsl:with-param name="lang" select="$lang02"/>
          <xsl:with-param name="templateName" select="concat('main_', $lang02)"/>
        </xsl:call-template>
       
        <pageTemplate id="domainList">
           <pageGraphics>
            <!-- TODO eliminate showBoundary -->
            <frame id="main" x1="2.1cm" y1="4.5cm" width="18.0cm" height="21.1cm" showBoundary="0"/>
            <image file="{$srcpath}cz_nic_logo_{$lang}.png" x="2.1cm" y="0.8cm" width="4.2cm"/>
            <stroke color="#C4C9CD"/>
            <lineMode width="0.01cm"/>
            <lines>7.1cm  1.3cm  7.1cm 0.5cm</lines>
            <lines>11.4cm 1.3cm 11.4cm 0.5cm</lines>
            <lines>14.6cm 1.3cm 14.6cm 0.5cm</lines>
            <lines>17.9cm 1.3cm 17.9cm 0.5cm</lines>
            <lineMode width="1"/>
            <fill color="#ACB2B9"/>
            <setFont name="Times-Roman" size="7"/>
            <drawString x="7.3cm" y="1.1cm">
              <xsl:value-of select="$loc/str[@name='CZ.NIC, z.s.p.o.']"/>
            </drawString>
            <drawString x="7.3cm" y="0.8cm">
              <xsl:value-of select="$loc/str[@name='Americka 23, 120 00 Prague 2']"/>
            </drawString>
            <drawString x="7.3cm" y="0.5cm">
              <xsl:value-of select="$loc/str[@name='Czech Republic']"/>
            </drawString>
            <drawString x="11.6cm" y="1.1cm"><xsl:value-of select="$loc/str[@name='T']"/> +420 222 745 111</drawString>
            <drawString x="11.6cm" y="0.8cm"><xsl:value-of select="$loc/str[@name='F']"/> +420 222 745 112</drawString>
            <drawString x="14.8cm" y="1.1cm"><xsl:value-of select="$loc/str[@name='IC']"/> 67985726</drawString>
            <drawString x="14.8cm" y="0.8cm"><xsl:value-of select="$loc/str[@name='DIC']"/> CZ67986726</drawString>
            <drawString x="18.1cm" y="1.1cm">kontakt@nic.cz</drawString>
            <drawString x="18.1cm" y="0.8cm">www.nic.cz</drawString>
          </pageGraphics>
        </pageTemplate>
      </template>

      <stylesheet>
        <paraStyle name="basic" fontName="Times-Roman"/>
        <paraStyle name="main" parent="basic" spaceAfter="0.6cm"/>
        <paraStyle name="address" fontSize="12" fontName="Times-Roman"/>
        <paraStyle name="address-name" parent="address" fontName="Times-Bold"/>
        <paraStyle name="tableItem" leading="10" fontName="Courier" fontSize="9"/>
        <paraStyle name="tableHead" leading="10" fontName="Times-Bold" fontSize="10"/>

        <blockTableStyle id="domainListTable">
            <blockAlignment value="CENTER" start="0,0" stop="-1,-1"/>
            <lineStyle kind="GRID" start="0,0" stop="-1,-1" colorName="black"/>
            <blockTopPadding length="2mm" start="0,0" stop="-1,-1" />
            <blockBottomPadding length="1mm" start="0,0" stop="-1,-1" />
        </blockTableStyle>

      </stylesheet>
      <story>
        <xsl:for-each select="holder">

          <xsl:choose>
              <xsl:when test="count(expiring_domain)&lt;=$listlimit">
                  <setNextTemplate>
                     <xsl:attribute name="name">
                         <xsl:value-of select="concat('main_',$lang01)"/>
                     </xsl:attribute>
                  </setNextTemplate>

                  <xsl:call-template name="onePage">
                    <xsl:with-param name="lang" select="$lang01"/>
                  </xsl:call-template>
                    <xsl:call-template name="domainsTable">
                    </xsl:call-template>

                  <setNextTemplate>
                     <xsl:attribute name="name">
                         <xsl:value-of select="concat('main_',$lang02)"/>
                     </xsl:attribute>
                  </setNextTemplate>

                  <nextFrame/>
                  <xsl:call-template name="onePage">
                    <xsl:with-param name="lang" select="$lang02"/>
                  </xsl:call-template>
                  <xsl:call-template name="domainsTable">
                  </xsl:call-template>
              </xsl:when>
              <xsl:otherwise> 

                  <setNextTemplate>
                     <xsl:attribute name="name">
                         <xsl:value-of select="concat('main_',$lang01)"/>
                     </xsl:attribute>
                  </setNextTemplate>

                  <xsl:call-template name="onePage">
                    <xsl:with-param name="lang" select="$lang01"/>
                  </xsl:call-template>

                  <setNextTemplate>
                     <xsl:attribute name="name">
                         <xsl:value-of select="concat('main_',$lang02)"/>
                     </xsl:attribute>
                  </setNextTemplate>

                  <nextFrame/>
                  <xsl:call-template name="onePage">
                    <xsl:with-param name="lang" select="$lang02"/>
                  </xsl:call-template>

                  <setNextTemplate name="domainList"/> 

                  <nextFrame/>
                    <xsl:call-template name="domainsTable">
                    </xsl:call-template>
                  <nextFrame/>
              </xsl:otherwise> 
          </xsl:choose>

            <!-- <setNextTemplate name="domainList"/> -->

        </xsl:for-each>
      </story>
    </document>
  </xsl:template>

  <!--one page of letter parametrized by language-->
  <xsl:template name="onePage">
    <xsl:param name="lang" select="'cs'"/>
    <xsl:variable name="loc" select="document(concat('translation_', $lang, '.xml'))/strings"/>
    <xsl:call-template name="fillAddress"> 
    </xsl:call-template>

    <para style="main"><xsl:value-of select="$loc/str[@name='Prague']"/>, <xsl:call-template name="local_date"><xsl:with-param name="sdt" select="actual_date"/></xsl:call-template></para>
    <para style="main"><b><xsl:value-of select="$loc/str[@name='Subject: Extension of registration of']"/></b></para>
    <spacer length="0.5cm"/>
    <para style="main"><xsl:value-of select="$loc/str[@name='Dear Sir or Madam']"/>
</para>
    <para style="main">
      <xsl:value-of select="$loc/str[@name='warning01']"/>
    </para>
    <para style="main">
      <xsl:value-of select="$loc/str[@name='warning02']"/>
      <b> <xsl:value-of select="$loc/str[@name='warning03']"/> </b>
      <xsl:value-of select="$loc/str[@name='warning04']"/>

    </para>
    <!-- Please notice ... -->
    <para style="basic" spaceAfter="0.3cm">

        <xsl:value-of select="$loc/str[@name='warning05']"/>
        <b>
        <xsl:value-of select="$loc/str[@name='warning06']"/>
        &SPACE;
        <xsl:call-template name="local_date">
            <xsl:with-param name="sdt" select="termination_date"/>
        </xsl:call-template>
        </b>
        &SPACE;
        <b><xsl:value-of select="$loc/str[@name='warning07']"/></b>
        <xsl:value-of select="$loc/str[@name='warning08']"/>
    </para>

    <para style="main"><xsl:value-of select="$loc/str[@name='The date of...']"/>
    </para>

    <para style="basic" spaceAfter="0.3cm"><xsl:value-of select="$loc/str[@name='Yours sincerely']"/>
    </para>
    <para style="basic">
        <xsl:value-of select="$loc/str[@name='Operations manager name']"/>
    </para>
    <para style="basic" spaceAfter="0.6cm">
      <xsl:value-of select="$loc/str[@name='Operations manager, CZ.NIC, z.s.p.o.']"/>
    </para>

    <para style="main"><b><xsl:value-of select="$loc/str[@name='Attachment']"/></b></para>

  </xsl:template>

  <!-- a table with list of expired domains -->
    <xsl:template name="domainsTable">

        <blockTable repeatRows="1" colWidths="8cm,4.5cm,6cm" style="domainListTable">
           <tr>
               <td> <para style="tableHead"> Domain / Doména </para> </td> 
               <td> <para style="tableHead"> Registrar / Registrátor </para></td> 
               <td> <para style="tableHead"> Registrar web / Web registrátora </para> </td>
           </tr>

           <xsl:for-each select="expiring_domain"> 
                <tr>
                    <td> 
                      <para style="tableItem">
                        <xsl:choose>
                            <xsl:when test="string-length(domain)&gt;41">
                                <xsl:value-of select="substring(domain,1,41)"/>&SPACE;<xsl:value-of select="substring(domain,42)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="domain"/>
                            </xsl:otherwise>
                        </xsl:choose>
                      </para>
                        


                        <!--
                        <xsl:call-template name="trim_with_dots">
                            <xsl:with-param name="string" select="domain"/>
                            <xsl:with-param name="max_length" select="38"/>
                        </xsl:call-template>
                        -->
                    </td>
                    <td> 
                        <para style="tableItem">
                        <xsl:value-of select="registrar"/>
                        </para>
                    </td>
                    <td> 
                      <para style="tableItem">
                        <xsl:choose>
                            <xsl:when test="string-length(registrar_web)&gt;30">
                                <xsl:value-of select="substring(registrar_web,1,30)"/>&SPACE;<xsl:value-of select="substring(registrar_web,31)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="registrar_web"/>
                            </xsl:otherwise>
                        </xsl:choose>
                      </para>
                    </td>
                </tr>
           </xsl:for-each>

        </blockTable>
    </xsl:template>

</xsl:stylesheet>
