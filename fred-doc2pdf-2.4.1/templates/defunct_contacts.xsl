<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
<!ENTITY SPACE "<xsl:text xmlns:xsl='http://www.w3.org/1999/XSL/Transform'> </xsl:text>">
<!ENTITY AMP "&#38;">
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" encoding="utf-8"/>
  <xsl:include href="shared_templates.xsl"/>
  <xsl:param name="lang" select="'cs'"/>
  <xsl:param name="srcpath" select="'templates/'" />
  <xsl:variable name="loc" select="document(concat('translation_', $lang, '.xml'))/strings"></xsl:variable>
  <!-- root template for rml document generation -->
  <xsl:template match="contacts">
    <document>
      <template pageSize="(21cm, 29.7cm)" leftMargin="2.0cm" rightMargin="2.0cm" topMargin="2.0cm" bottomMargin="2.0cm" title="Non-functional record in the domain registry" author="CZ.NIC">

          <!-- page templates -->

        <xsl:call-template name="letterTemplate">
          <xsl:with-param name="lang" select="'cs'"/>
          <xsl:with-param name="templateName" select="'main_cs'"/>
        </xsl:call-template>
        <xsl:call-template name="letterTemplate">
          <xsl:with-param name="lang" select="'en'"/>
          <xsl:with-param name="templateName" select="'main_en'"/>
        </xsl:call-template>

        <pageTemplate id="first" pageSize="(29.7cm, 21cm)" leftMargin="1.1cm" rightMargin="1.1cm" topMargin="1.8cm" bottomMargin="1.3cm">

          <frame id="delivery" x1="0.8cm" y1="0.8cm" width="28cm" height="17.6cm" showBoundary="0"/>
        </pageTemplate>



      </template>
      <stylesheet>
        <paraStyle name="main" spaceAfter="0.4cm" fontName="Times-Roman"/>
        <paraStyle name="address" fontSize="12" fontName="Times-Roman"/>
        <paraStyle name="address-name" parent="address" fontSize="12" fontName="Times-Bold"/>

                        <!-- subject -->
        <paraStyle name="subject" spaceAfter="0.4cm" fontSize="12" fontName="Times-Bold"/>
        <blockTableStyle id="tbl_delivery">
          <blockAlignment value="CENTER" start="0,0" stop="5,2"/>
          <blockValign value="BOTTOM" start="0,0" stop="4,2"/>
          <blockValign value="MIDDLE" start="5,0" stop="-1,2"/>
          <blockValign value="MIDDLE" start="0,3" stop="-1,-1"/>
          <blockFont name="Times-Roman" size="8" start="0,0" stop="-1,-1"/>
          <lineStyle kind="GRID" start="0,3" stop="-1,-1" colorName="black"/>
          <lineStyle kind="BOX" start="0,0" stop="-1,2" colorName="black"/>
          <lineStyle kind="LINEAFTER" start="6,0" stop="6,1" colorName="black"/>
          <lineStyle kind="LINEAFTER" start="0,0" stop="4,2" colorName="black"/>
          <lineStyle kind="LINEAFTER" start="8,0" stop="8,2" colorName="black"/>
          <lineStyle kind="LINEAFTER" start="10,0" stop="10,2" colorName="black"/>
          <lineStyle kind="LINEAFTER" start="12,0" stop="12,2" colorName="black"/>
          <lineStyle kind="LINEAFTER" start="5,1" stop="5,1" colorName="black"/>
          <lineStyle kind="LINEAFTER" start="7,1" stop="7,1" colorName="black"/>
          <lineStyle kind="LINEAFTER" start="9,1" stop="9,2" colorName="black"/>
          <lineStyle kind="LINEAFTER" start="11,1" stop="11,2" colorName="black"/>
          <lineStyle kind="LINEBELOW" start="5,0" stop="12,0" colorName="black"/>
          <lineStyle kind="LINEBELOW" start="5,1" stop="12,1" colorName="black"/>
        </blockTableStyle>


        <blockTableStyle id="test01">
            <blockFont name="Times-Roman" start="0,0" stop="-1,-1" size="9"/>
            <blockAlignment value="RIGHT" start="1,0" stop="-1,-1"/>
            <!--
            <lineStyle kind="GRID" start="0,0" stop="-1,-1" colorName="black"/>
            <lineStyle kind="LINEABOVE" start="0,0" stop="-1,0" thickness="0.5" colorName="black"/>
            <lineStyle kind="LINEBELOW" start="0,-1" stop="-1,-1" thickness="0.5" colorName="black"/>
            -->
            <blockTopPadding length="0" start="0,0" stop="-1,-1" />
            <blockBottomPadding length="0" start="0,0" stop="-1,-1" />
            <blockBottomPadding length="0.5cm" start="0,-1" stop="-1,-1" />
        </blockTableStyle>



        <paraStyle name="th" fontSize="8"/>
      </stylesheet>

      <!-- content itself -->

      <story>

        <xsl:for-each select="contact">
            <setNextTemplate name="main_cs"/>
          <xsl:call-template name="onePageObsoleteContact">
            <xsl:with-param name="lang" select="'cs'"/>
          </xsl:call-template>


          <setNextTemplate name="main_en"/>
          <nextFrame/>

          <xsl:call-template name="onePageObsoleteContact">
            <xsl:with-param name="lang" select="'en'"/>
          </xsl:call-template>
          <nextFrame/>

        </xsl:for-each>
      </story>
    </document>
  </xsl:template>

  <!--one page of letter parametrized by language-->
  <xsl:template name="onePageObsoleteContact">
    <xsl:param name="lang" select="'cs'"/>
    <xsl:variable name="loc" select="document(concat('translation_', $lang, '.xml'))/strings"/>

    <xsl:call-template name="fillAddress"> 
    </xsl:call-template>
   
    <!-- beginning -->
    <para style="subject"><xsl:value-of select="$loc/str[@name='Subject: Notice re...']"/></para>
            
    <para style="main"><xsl:value-of select="$loc/str[@name='Dear Sir or Madam']"/>
    </para>

    <xsl:choose>
        <xsl:when test="$lang='cs'">

            <!-- TODO - move the text to translation_* like it is in warning_letters.xsl -->
            <para style="main">
                sdružení CZ.NIC zaznamenalo v rámci pravidelně probíhajících kontrol údajů v centrálním registru doménových jmen .cz, že v záznamu o Vaší kontaktní osobě je uveden <b>nefunkční či neexistující e-mail</b>
            </para>
        </xsl:when>
        <xsl:otherwise>
            <para style="main">
                During regular data checks in the central .cz domain name registry, the CZ.NIC Association has noticed that in the record for your contact person the given <b>email does not work or does not exist.</b>
            </para>
        </xsl:otherwise>
    </xsl:choose>    
    <xsl:choose>
        <xsl:when test="$lang='cs'">

            <!-- TODO - move the text to translation_* like it is in warning_letters.xsl -->
            <para style="main">
                Vzhledem k tomu, že e-mail je jedním z <b>důležitých a povinných údajů v registru,</b> žádáme Vás o jeho <b>urychlenou (okamžitou) opravu.</b> Níže naleznete výpis údajů, které jsou o Vaší osobě evidovány; zjistíte-li jakékoliv další neplatné či nesprávné údaje, 
                <b>opravte je, prosím, také.</b>
            </para>
        </xsl:when>
        <xsl:otherwise>
            <para style="main">
                Since the email is one of the <b>important and mandatory details in the registry,</b> we ask you to <b> fix this urgently (immediately). </b>Below you will find an extract of the details which are recorded for your contact person; if you notice any other invalid or incorrect details, <b>please correct them too.</b>
            </para>
        </xsl:otherwise>
    </xsl:choose>    

     <xsl:choose>
         <!-- <xsl:when test="registrar='CZ.NIC, z.s.p.o.'">.-->
             <xsl:when test="contains(registrar, 'CZ.NIC')">

                <para style="main">
                    <xsl:value-of select="$loc/str[@name='Make the change...']"/>.
                </para>
             <spacer length="0.9cm"/>
         </xsl:when>
         <xsl:otherwise>
                <para style="main">
                    <xsl:value-of select="$loc/str[@name='Make the change...']"/>:
                </para>
              <para><xsl:value-of select="$loc/str[@name='Designated registrar']"/>:&SPACE;<xsl:value-of select="registrar"/>
             </para>
             <para><xsl:value-of select="$loc/str[@name='www']"/>&SPACE;<xsl:value-of select="registrar_web"/>
             </para>

             <spacer length="0.6cm"/>
         </xsl:otherwise>
     </xsl:choose>

     <para style="main">
         <xsl:value-of select="$loc/str[@name='Details recorded for your contact']"/>
     </para>


     <!--
    <blockTable style="contact_details" x="1.0cm" colWidths="5.0cm,5.0cm">
    <blockTable style="contact_details" align="LEFT">
    <blockTable align="LEFT" style="tbl_delivery">
    <blockTable align="LEFT">
    <blockTable colWidths="3cm,5.7cm" repeatRows="1" style="test01">
    -->
    <blockTable repeatRows="1" style="test01">


        <tr> <td>

           <xsl:value-of select="$loc/str[@name='organization']"/> </td> <td> 
           <xsl:choose>
              <xsl:when test="string-length(organization)>50">
                  <xsl:value-of select="substring(organization, 1, 50)"/>... </xsl:when>
              <xsl:otherwise> 
                  <xsl:value-of select="organization"/>
              </xsl:otherwise>
           </xsl:choose>

     </td> </tr>

     <tr> <td>
                <xsl:value-of select="$loc/str[@name='name']"/> </td> <td>  
           <xsl:choose>
              <xsl:when test="string-length(name)>50">
                  <xsl:value-of select="substring(name, 1, 50)"/>... </xsl:when>
              <xsl:otherwise> 
                  <xsl:value-of select="name"/>
              </xsl:otherwise>
           </xsl:choose>
     </td> </tr>

     <tr> <td><xsl:value-of select="$loc/str[@name='address']"/> </td> <td> <xsl:value-of select="street1"/>
     </td> </tr>
    <tr> <td><xsl:value-of select="$loc/str[@name='Identifier']"/> </td> <td> <xsl:value-of select="handle"/>
     </td> </tr>
     <tr> <td><xsl:value-of select="$loc/str[@name='DIC']"/>: </td> <td> <xsl:value-of select="vat"/>
     </td> </tr>
     <tr> <td><xsl:value-of select="$loc/str[@name='Identification type']"/> </td> <td> <xsl:value-of select="ssn_type"/>
     </td> </tr>
    <tr> <td><xsl:value-of select="$loc/str[@name='ID']"/> </td> <td> <xsl:value-of select="ssn"/>
     </td> </tr>
     <tr> <td><xsl:value-of select="$loc/str[@name='email']"/> </td> <td> <xsl:value-of select="email"/>
     </td> </tr>
    <tr> <td><xsl:value-of select="$loc/str[@name='notify_email']"/> </td> <td> <xsl:value-of select="notify_email"/>
     </td> </tr>
    <tr> <td><xsl:value-of select="$loc/str[@name='telephone']"/> </td> <td> <xsl:value-of select="telephone"/>
     </td> </tr>

     <!-- TODO
     <xsl:if test="fax">
     <tr> <td><xsl:value-of select="$loc/str[@name='fax']"/> </td> <td> <xsl:value-of select="fax"/>
     </td> </tr>
     </xsl:if>
     -->

     <tr> <td> <xsl:value-of select="$loc/str[@name='Last update']"/> </td> <td> <xsl:value-of select="last_update"/>
     </td> </tr>

    </blockTable>

    <!-- so far 

    <para style="main"><xsl:value-of select="$loc/str[@name='Prague']"/>, <xsl:call-template name="local_date"><xsl:with-param name="sdt" select="actual_date"/></xsl:call-template></para>
    <para style="main"><xsl:value-of select="$loc/str[@name='Subject: Extension of registration of']"/>&SPACE;<xsl:value-of select="domain"/>&SPACE;<xsl:value-of select="$loc/str[@name='domain(subject)']"/></para>
    <spacer length="1.2cm"/>
    <para style="main"><xsl:value-of select="$loc/str[@name='Dear holder of']"/>&SPACE;<xsl:value-of select="domain"/>&SPACE;<xsl:value-of select="$loc/str[@name='domain name']"/>,
    </para>

    <para style="main">
      <xsl:value-of select="$loc/str[@name='The CZ.NIC z.s.p.o. company, an administrator...']"/>
    </para>

    <para style="main">
      <xsl:value-of select="$loc/str[@name='Should you be interested in keeping this domain name...']"/>
    </para>

    <para style="main"><xsl:value-of select="$loc/str[@name='hould the registration of the domain name...']"/>&SPACE;<xsl:call-template name="local_date"><xsl:with-param name="sdt" select="termination_date"/></xsl:call-template>&SPACE;<xsl:value-of select="$loc/str[@name='and the domain name shall be open...']"/></para>
    <para style="main"><xsl:value-of select="$loc/str[@name='The following information was recorded on the CZ.NIC Central database as of the date of issuance of this letter']"/>:
    </para>



    <spacer length="0.6cm"/>
    <para><xsl:value-of select="$loc/str[@name='Domain name']"/>: <xsl:value-of select="domain"/></para>
    <para><xsl:value-of select="$loc/str[@name='Holder']"/>: <xsl:value-of select="holder/name"/> (ID: <xsl:value-of select="holder/handle"/>)</para>
    <para><xsl:value-of select="$loc/str[@name='Designated registrar']"/>: <xsl:value-of select="registrar"/></para>
    <para><xsl:value-of select="$loc/str[@name='Date of termination of the registration']"/>: <xsl:call-template name="local_date"><xsl:with-param name="sdt" select="termination_date"/></xsl:call-template></para>
            -->


    <spacer length="0.8cm"/>
    <para>Ing. Martin Peterka</para>
    <para>
      <xsl:value-of select="$loc/str[@name='Operations manager, CZ.NIC, z.s.p.o.']"/>
    </para>

  </xsl:template>
</xsl:stylesheet>
