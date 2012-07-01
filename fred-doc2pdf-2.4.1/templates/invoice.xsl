<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
<!ENTITY SPACE "<xsl:text xmlns:xsl='http://www.w3.org/1999/XSL/Transform'> </xsl:text>">
]>
<!-- 
Usage:
$ xsltproc -stringparam srcpath yourpath/templates/ -stringparam lang en yourpath/templates/invoice.xsl yourpath/examples/invoice.xml
-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="xml" encoding="utf-8" />
<xsl:param name="srcpath" select="'templates/'" />
<xsl:param name="lang" select="'cs'" />
<xsl:variable name="loc" select="document(concat('translation_', $lang, '.xml'))/strings"/>

<xsl:decimal-format name="CZK" decimal-separator="." grouping-separator=" "/>

<xsl:template name="local_date">
    <xsl:param name="sdt"/>
    <xsl:if test="$sdt">
    <xsl:value-of select='substring($sdt, 9, 2)' />.<xsl:value-of select='substring($sdt, 6, 2)' />.<xsl:value-of select='substring($sdt, 1, 4)' />
    </xsl:if>
</xsl:template>


<xsl:template match="/invoice">
<document>

<template pageSize="(21cm, 29.7cm)" leftMargin="2.0cm" rightMargin="2.0cm" topMargin="2.0cm" bottomMargin="2.0cm" 
  title="{$loc/str[@name='Invoice No']} {payment/invoice_number}"
  author="{supplier/name}"
  >
    <pageTemplate id="first">
      <pageGraphics>
        <fill color="#035e79" />
        <rect x="0" y="26.4cm" width="21cm" height="3.3cm" fill="yes" stroke="no" />

        <image file="{$srcpath}white-balls.png" x="12.2cm" y="26.8cm" width="2cm"/>

        <fill color="white" />
        <setFont name="Times-Roman" size="14"/>
        <drawRightString x="19.3cm" y="27.9cm">
            <xsl:choose>
                <xsl:when test="number(delivery/sumarize/total)&lt;0">
                    <xsl:value-of select="$loc/str[@name='Tax credit']"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$loc/str[@name='Invoice / Vat voucher']"/>
                </xsl:otherwise>        
            </xsl:choose>
            
        </drawRightString>
        <drawRightString x="19.3cm" y="27cm"><xsl:value-of select="$loc/str[@name='No']"/>. <xsl:value-of select="payment/invoice_number"/></drawRightString>

        <stroke color="#035e79"/>
        <lineMode width="0.1cm"/>
        <lines>0.9cm 25.55cm 1.4cm 25.55cm</lines>
        <lines>0.9cm  20.5cm 1.4cm  20.5cm</lines>

        <lines>10cm 20.9cm 10.5cm 20.9cm</lines>
        <lines>10cm 19.7cm 10.5cm 19.7cm</lines>
        <lines>10cm   17cm 10.5cm   17cm</lines>

        <!-- left column -->

        <fill color="black" />
        <setFont name="Times-Roman" size="9" />
        <drawString x="1.6cm" y="25.9cm"><xsl:value-of select="$loc/str[@name='Client']"/>:</drawString>
        <setFont name="Times-Bold" size="11" />
        <drawString x="1.6cm" y="25.4cm"><xsl:value-of select="client/name"/></drawString>
        <drawString x="1.6cm" y="24.9cm"><xsl:value-of select="client/address/street"/></drawString>
        <drawString x="1.6cm" y="24.4cm"><xsl:value-of select="client/address/zip"/>&SPACE;<xsl:value-of select="client/address/city"/></drawString>

        <setFont name="Times-Bold" size="9" />
        <drawString x="1.6cm" y="23.7cm"><xsl:value-of select="$loc/str[@name='ICO']"/>:</drawString>
        <drawRightString x="8.6cm" y="23.7cm"><xsl:value-of select="client/ico"/></drawRightString>
        <drawString x="1.6cm" y="23.3cm"><xsl:value-of select="$loc/str[@name='VAT number']"/>:</drawString>
        <drawRightString x="8.6cm" y="23.3cm"><xsl:value-of select="client/vat_number"/></drawRightString>

        <setFont name="Times-Roman" size="9" />
        <drawString x="1.6cm" y="22.5cm"><xsl:value-of select="$loc/str[@name='Customer residence']"/>:</drawString>
        <drawString x="1.6cm" y="22.1cm"><xsl:value-of select="client/address/street"/></drawString>
        <drawString x="1.6cm" y="21.7cm"><xsl:value-of select="client/address/zip"/>&SPACE;<xsl:value-of select="client/address/city"/></drawString>

        <drawString x="1.6cm" y="20.8cm"><xsl:value-of select="$loc/str[@name='Supplier']"/>:</drawString>
        <drawString x="1.6cm" y="20.4cm"><xsl:value-of select="$loc/str[@name='CZ.NIC, z.s.p.o.']"/></drawString>
        <drawString x="1.6cm" y="20cm"><xsl:value-of select="supplier/address/street"/></drawString>
        <drawString x="1.6cm" y="19.6cm"><xsl:value-of select="supplier/address/zip"/>&SPACE;<xsl:value-of select="supplier/address/city"/></drawString>

        <drawString x="1.6cm" y="18.7cm"><xsl:value-of select="$loc/str[@name='ICO']"/>:</drawString>
        <drawRightString x="7cm" y="18.7cm"><xsl:value-of select="supplier/ico"/></drawRightString>
        <drawString x="1.6cm" y="18.3cm"><xsl:value-of select="$loc/str[@name='VAT number']"/>:</drawString>
        <drawRightString x="7cm" y="18.3cm"><xsl:value-of select="supplier/vat_number"/></drawRightString>

        <drawString x="1.6cm" y="17.4cm"><xsl:value-of select="$loc/str[@name='SpZ']"/>:</drawString>
        <drawString x="1.6cm" y="16.9cm"><xsl:value-of select="$loc/str[@name='department of the civil law agenda']"/></drawString>
        <drawString x="1.6cm" y="16.5cm"><xsl:value-of select="$loc/str[@name='Municipal Prague cap.city, no ZS/30/3/98']"/></drawString>

        <!-- right column -->
        <setFont name="Times-Bold" size="9" />
        <drawString x="10.7cm" y="20.8cm"><xsl:value-of select="$loc/str[@name='Vat voucher']"/>&SPACE;<xsl:value-of select="$loc/str[@name='No']"/>.:</drawString>
        <drawRightString x="19.3cm" y="20.8cm"><xsl:value-of select="payment/invoice_number"/></drawRightString>
        <drawString x="10.7cm" y="20.4cm"><xsl:value-of select="$loc/str[@name='Variable symbol']"/>:</drawString>
        <drawRightString x="19.3cm" y="20.4cm"><xsl:value-of select="payment/vs"/></drawRightString>

        <setFont name="Times-Roman" size="9" />
        <drawString x="10.7cm" y="19.6cm"><xsl:value-of select="$loc/str[@name='Invoice date']"/>:</drawString>
        <drawRightString x="19.3cm" y="19.6cm"><xsl:call-template name="local_date"><xsl:with-param name="sdt" select="payment/invoice_date" /></xsl:call-template></drawRightString>
        <drawString x="10.7cm" y="19.2cm"><xsl:value-of select="$loc/str[@name='Tax point']"/>:</drawString>
        <drawRightString x="19.3cm" y="19.2cm"><xsl:call-template name="local_date"><xsl:with-param name="sdt" select="payment/tax_point" /></xsl:call-template></drawRightString>

        <drawString x="10.7cm" y="16.9cm"><xsl:value-of select="$loc/str[@name='Sheet']"/>: 1</drawString>
        <drawRightString x="19.3cm" y="16.9cm"><xsl:value-of select="$loc/str[@name='Number of sheets']"/>: <pageNumberTotal/></drawRightString>
        <drawString x="10.7cm" y="16.5cm"><xsl:value-of select="$loc/str[@name='Draw by CZ.NIC invoice system']"/></drawString>


        <stroke color="black"/>
        <lineMode width="0.5"/>
        <lines>1.6cm 16.1cm 19.3cm 16.1cm</lines>
        
        <frame id="delivery" x1="1.36cm" y1="3.6cm" width="18.2cm" height="12.4cm" showBoundary="0" />

        <image file="{$srcpath}cz_nic_logo_{$lang}.png" x="1.3cm" y="0.8cm" width="4.2cm"/>
        <stroke color="#C4C9CD"/>
        <lineMode width="0.01cm"/>
        <lines>7.1cm  1.3cm  7.1cm 0.5cm</lines>
        <lines>11.4cm 1.3cm 11.4cm 0.5cm</lines>
        <lines>14.6cm 1.3cm 14.6cm 0.5cm</lines>
        <lines>17.6cm 1.3cm 17.6cm 0.5cm</lines>
        <lineMode width="1"/>
        <fill color="#ACB2B9"/>
        <setFont name="Times-Roman" size="7"/>
        <drawString x="7.3cm" y="1.1cm"><xsl:value-of select="$loc/str[@name='CZ.NIC, z.s.p.o.']"/></drawString>
        <drawString x="7.3cm" y="0.8cm"><xsl:value-of select="supplier/address/street"/>, <xsl:value-of select="supplier/address/zip"/>&SPACE;<xsl:value-of select="supplier/address/city"/></drawString>
        <drawString x="7.3cm" y="0.5cm"><xsl:value-of select="$loc/str[@name='Czech Republic']"/></drawString>
        <drawString x="11.6cm" y="1.1cm"><xsl:value-of select="$loc/str[@name='T']"/>&SPACE;<xsl:value-of select="supplier/phone"/></drawString>
        <drawString x="11.6cm" y="0.8cm"><xsl:value-of select="$loc/str[@name='F']"/>&SPACE;<xsl:value-of select="supplier/fax"/></drawString>
        <drawString x="14.8cm" y="1.1cm"><xsl:value-of select="$loc/str[@name='IC']"/>&SPACE;<xsl:value-of select="supplier/ico"/></drawString>
        <drawString x="14.8cm" y="0.8cm"><xsl:value-of select="$loc/str[@name='DIC']"/>&SPACE;<xsl:value-of select="supplier/vat_number"/></drawString>
        <drawString x="17.8cm" y="1.1cm"><xsl:value-of select="supplier/email"/></drawString>
        <drawString x="17.8cm" y="0.8cm"><xsl:value-of select="supplier/url"/></drawString>
      </pageGraphics>
    </pageTemplate>

    <pageTemplate id="appendix">
      <pageGraphics>
        <fill color="#035e79" />
        <rect x="0" y="26.4cm" width="21cm" height="3.3cm" fill="yes" stroke="no" />

        <fill color="white" />
        <setFont name="Times-Roman" size="9"/>
        <drawString x="1.6cm" y="27cm"><xsl:value-of select="$loc/str[@name='Sheet']"/>: <pageNumber/></drawString>
        <drawString x="5.1cm" y="27cm"><xsl:value-of select="$loc/str[@name='Number of sheets']"/>: <pageNumberTotal/></drawString>

        <setFont name="Times-Roman" size="14"/>
        <drawRightString x="14.4cm" y="27cm"><xsl:value-of select="$loc/str[@name='Invoice attachment']"/></drawRightString>
        <drawRightString x="19.3cm" y="27cm"><xsl:value-of select="$loc/str[@name='No']"/>. <xsl:value-of select="payment/invoice_number"/></drawRightString>

        <stroke color="#035e79"/>
        <lineMode width="0.1cm"/>
        <lines>0.8cm 25.5cm 1.3cm 25.5cm</lines>

        <frame id="delivery" x1="1.36cm" y1="3.5cm" width="18.2cm" height="22.5cm" showBoundary="0" />

        <image file="{$srcpath}cz_nic_logo_{$lang}.png" x="1.3cm" y="0.8cm" width="4.2cm"/>
        <stroke color="#C4C9CD"/>
        <lineMode width="0.01cm"/>
        <lines>7.1cm  1.3cm  7.1cm 0.5cm</lines>
        <lines>11.4cm 1.3cm 11.4cm 0.5cm</lines>
        <lines>14.6cm 1.3cm 14.6cm 0.5cm</lines>
        <lines>17.6cm 1.3cm 17.6cm 0.5cm</lines>
        <lineMode width="1"/>
        <fill color="#ACB2B9"/>
        <setFont name="Times-Roman" size="7"/>
        <drawString x="7.3cm" y="1.1cm"><xsl:value-of select="$loc/str[@name='CZ.NIC, z.s.p.o.']"/></drawString>
        <drawString x="7.3cm" y="0.8cm"><xsl:value-of select="supplier/address/street"/>, <xsl:value-of select="supplier/address/zip"/>&SPACE;<xsl:value-of select="supplier/address/city"/></drawString>
        <drawString x="7.3cm" y="0.5cm"><xsl:value-of select="$loc/str[@name='Czech Republic']"/></drawString>
        <drawString x="11.6cm" y="1.1cm"><xsl:value-of select="$loc/str[@name='T']"/>&SPACE;<xsl:value-of select="supplier/phone"/></drawString>
        <drawString x="11.6cm" y="0.8cm"><xsl:value-of select="$loc/str[@name='F']"/>&SPACE;<xsl:value-of select="supplier/fax"/></drawString>
        <drawString x="14.8cm" y="1.1cm"><xsl:value-of select="$loc/str[@name='IC']"/>&SPACE;<xsl:value-of select="supplier/ico"/></drawString>
        <drawString x="14.8cm" y="0.8cm"><xsl:value-of select="$loc/str[@name='DIC']"/>&SPACE;<xsl:value-of select="supplier/vat_number"/></drawString>
        <drawString x="17.8cm" y="1.1cm"><xsl:value-of select="supplier/email"/></drawString>
        <drawString x="17.8cm" y="0.8cm"><xsl:value-of select="supplier/url"/></drawString>
      </pageGraphics>
    </pageTemplate>

</template>

<stylesheet>

    <paraStyle fontSize="9"/>

    <blockTableStyle id="tbl_delivery">
      <lineStyle kind="LINEABOVE" start="0,0"  stop="-1,0"  thickness="0.5" colorName="black"/>
      <lineStyle kind="LINEBELOW" start="0,-1" stop="-1,-1" thickness="0.5" colorName="black"/>
      <blockAlignment value="RIGHT" start="1,0" stop="3,-1"/>
      <blockFont name="Times-Bold" start="0,-1" stop="-1,-1" />
      <blockLeftPadding length="0" start="0,0" stop="0,-1" />
      <blockTopPadding length="0" start="0,1" stop="-1,-2" />
      <blockBottomPadding length="0" start="0,0" stop="-1,-2" />
      <blockTopPadding length="0.3cm" start="0,0" stop="-1,0" />
      <blockTopPadding length="0.3cm" start="0,-1" stop="-1,-1" />
      <blockBottomPadding length="0.2cm" start="0,-1" stop="-1,-1" />
    </blockTableStyle>

    <blockTableStyle id="tbl_advance_payment">
      <blockFont name="Times-Roman" start="0,0" stop="-1,-1" size="9"/>
      <blockAlignment value="RIGHT" start="1,0" stop="-1,-1"/>
      <blockFont name="Times-Bold" start="0,0" stop="-1,1"/>
      <lineStyle kind="LINEABOVE" start="0,0" stop="-1,0" thickness="0.5" colorName="black"/>
      <lineStyle kind="LINEBELOW" start="0,-1" stop="-1,-1" thickness="0.5" colorName="black"/>
      <blockLeftPadding length="0" start="0,0" stop="0,-1" />
    <!-- shring space between table header lines -->
      <blockTopPadding length="0" start="0,1" stop="-1,-1" />
      <blockBottomPadding length="0" start="0,0" stop="-1,0" />

    <!-- shring space between table lines -->
      <blockTopPadding length="0" start="0,2" stop="-1,-2" />
      <blockBottomPadding length="0" start="0,2" stop="-1,-2"/>

    <!-- indent bottom line -->
      <blockBottomPadding length="0.3cm" start="0,-1" stop="-1,-1" />
      <blockRightPadding length="0" start="-1,0" stop="-1,-1" />
    </blockTableStyle>

    <blockTableStyle id="appendix">
      <blockFont name="Times-Roman" start="0,0" stop="-1,-1" size="8"/>
      <blockAlignment value="RIGHT" start="4,0" stop="-1,-1"/>

      <!-- line and text bottom -->
      <blockLeftPadding length="0" start="0,0" stop="0,-1" />
      <blockRightPadding length="0" start="-1,0" stop="-1,-1" />
      <blockTopPadding length="-2" start="0,0" stop="-1,-1" />
      <blockBottomPadding length="0" start="0,0" stop="-1,-2" />

      <!-- padding table header -->
      <blockBottomPadding length="0.1cm" start="0,1" stop="-1,1" />
      <lineStyle kind="LINEBELOW" start="0,1" stop="-1,1" thickness="0.5" colorName="black"/>
      <blockTopPadding length="0.2cm" start="0,2" stop="-1,2" />

    </blockTableStyle>

    <blockTableStyle id="sumarize_items">
      <lineStyle kind="LINEABOVE" start="0,0" stop="-1,0" thickness="0.5" colorName="black"/>
      <blockFont name="Times-Bold" start="0,0" stop="-1,1"/>
      <blockTopPadding length="0.1cm" start="0,-1" stop="-1,-1" />
    </blockTableStyle>

    <paraStyle name="delivery-info" fontSize="9"/>

    <blockTableStyle id="tbl_service_codes">
      <blockFont name="Times-Roman" start="0,0" stop="-1,-1" size="9"/>
      <blockLeftPadding length="0" start="0,0" stop="-1,-1" />
      <blockTopPadding length="0" start="0,1" stop="-1,-1" />
      <blockBottomPadding length="-1" start="0,0" stop="-1,-1" />
    </blockTableStyle>

</stylesheet>

<story>

<spacer length="0.4cm"/>

<illustration width="0.5cm" height="1">
        <stroke color="#035e79"/>
        <lineMode width="0.1cm"/>
        <lines>-0.67cm -0.24cm -0.17cm -0.24cm</lines>
</illustration>
<para><xsl:value-of select="$loc/str[@name='Supply sign']"/>:</para>

<spacer length="0.4cm"/>
<para style="delivery-info">
<xsl:choose>
<!--
Description of decision, what text will be shown:

    if {delivery/sumarize/total} < 0
        "Tax credit text" {payment/tax_credit_number}
    else
        "Period from(date)" {payment/period_from} "to(date)" {payment/period_to}
        if appendix/items/item > 0
            "[we-invoiced-you] Vám fakturujeme poskytnuté služby..."
        else
            if {YEAR(payment/period_to)} < {YEAR(payment/invoice_date)}
                "[contractual-fine] Vám fakturujeme smluvní pokutu..."
            else
                "[years-fee] Vám fakturujeme roční poplatek..."
-->
 <xsl:when test="number(delivery/sumarize/total)&lt;0">
  <xsl:value-of select="$loc/str[@name='Tax credit text']"/>
  <xsl:text> </xsl:text>
  <xsl:value-of select="payment/tax_credit_number"/>
 </xsl:when>
 <xsl:otherwise>
  <xsl:value-of select="$loc/str[@name='Period from(date)']"/>&SPACE; 
  <xsl:call-template name="local_date">
   <xsl:with-param name="sdt" select="payment/period_from"/>
  </xsl:call-template> &SPACE;
  <xsl:value-of select="$loc/str[@name='to(date)']"/>&SPACE; 
  <xsl:call-template name="local_date">
   <xsl:with-param name="sdt" select="payment/period_to" />
  </xsl:call-template> &SPACE;
  <xsl:choose>
   <xsl:when test="count(appendix/items/item)">
    <xsl:value-of select="$loc/str[@name='we-invoiced-you']"/>
    <spacer length="0.4cm"/>
   </xsl:when>
   <xsl:otherwise>
    <xsl:choose>
     <xsl:when test="substring-before(payment/period_to,'-') &lt; substring-before(payment/invoice_date,'-')">
      <xsl:value-of select="$loc/str[@name='contractual-fine']"/>:
     </xsl:when>
     <xsl:otherwise>
      <xsl:value-of select="$loc/str[@name='years-fee']"/>:
     </xsl:otherwise>
    </xsl:choose>
   </xsl:otherwise>
  </xsl:choose>
 </xsl:otherwise>
</xsl:choose>
</para>
<xsl:if test="count(appendix/items/item)">

<blockTable colWidths="1.1cm,16.7cm" style="tbl_service_codes">
  <tr>
    <td><xsl:value-of select="$loc/str[@name='Service codes']"/>:</td>
    <td></td>
  </tr>
  <tr>
    <td>RREG:</td>
    <td><xsl:value-of select="$loc/str[@name='Domain name registration']"/></td>
  </tr>
  <tr>
    <td>RUDR:</td>
    <td><xsl:value-of select="$loc/str[@name='Domain name record maintenance']"/></td>
  </tr>
  <tr>
    <td>REPP:</td>
    <td><xsl:value-of select="$loc/str[@name='Charged queries']"/></td>
  </tr>
</blockTable>

</xsl:if>


<xsl:apply-templates select="delivery" />

  <setNextTemplate name="appendix"/>
<xsl:apply-templates select="advance_payment" />
<xsl:if test="count(appendix/items/item)">
  <xsl:apply-templates select="appendix" />
</xsl:if>
</story>

</document>
</xsl:template>

<xsl:template match="delivery">
<spacer length="0.4cm"/>

<blockTable colWidths="5cm,4.2cm,2cm,3cm,3.6cm" style="tbl_delivery" >
<xsl:apply-templates select="vat_rates" />
<tr>
    <td><xsl:value-of select="$loc/str[@name='To be paid']"/>:</td>
    <td><xsl:value-of select='format-number(sumarize/to_be_paid, "### ##0.00", "CZK")' /></td>
    <td></td>
    <td></td>
    <td></td>
</tr>
</blockTable>
</xsl:template>

<xsl:template match="vat_rates">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="entry">
<tr>
    <td><xsl:value-of select="$loc/str[@name='Total']"/>(<xsl:value-of select='format-number(vatperc, "#0")'/>%):</td>
    <td><xsl:value-of select='format-number(total, "### ##0.00", "CZK")' /></td>
    <td><xsl:value-of select="$loc/str[@name='VAT']"/>&SPACE;<xsl:value-of select='format-number(vatperc, "#0")'/>%</td>
    <td><xsl:value-of select='format-number(totalvat, "### ##0.00", "CZK")' /></td>
    <td></td>
</tr>
<tr>
    <td><xsl:value-of select="$loc/str[@name='Paid']"/>(<xsl:value-of select='format-number(vatperc, "#0")'/>%):</td>
    <td><xsl:value-of select='format-number(- paid, "### ##0.00", "CZK")' /></td>
    <td><xsl:value-of select="$loc/str[@name='VAT']"/>&SPACE;<xsl:value-of select='format-number(vatperc, "#0")'/>%</td>
    <td><xsl:value-of select='format-number(- paidvat, "### ##0.00", "CZK")' /></td>
    <td></td>
</tr>

<tr>
    <td><xsl:value-of select="$loc/str[@name='Tax base']"/>&SPACE;<xsl:value-of select='format-number(vatperc, "#0")' />%:</td>
    <td><xsl:value-of select='format-number(basetax, "### ##0.00", "CZK")' /></td> 
     <!-- <td><xsl:value-of select='format-number(0, "### ##0.00", "CZK")' /></td> --> <!-- there should be allways 0 -->
    <td></td>
    <td></td>
    <td></td>
</tr>
<tr>
    <td><xsl:value-of select="$loc/str[@name='VAT']"/>&SPACE;<xsl:value-of select='format-number(vatperc, "#0")' />%:</td>
    <td><xsl:value-of select='format-number(vat, "### ##0.00", "CZK")' /></td> 
<!-- there should be allways 0 -->
<!--<td><xsl:value-of select='format-number(0, "### ##0.00", "CZK")' /></td> -->
    <td></td>
    <td></td>
    <td></td>
</tr>
</xsl:template>

<xsl:template match="advance_payment">
<spacer length="0.6cm"/>
<illustration width="0.5cm" height="1">
        <stroke color="#035e79"/>
        <lineMode width="0.1cm"/>
        <lines>-0.67cm -0.24cm -0.17cm -0.24cm</lines>
</illustration>
<para><xsl:value-of select="$loc/str[@name='VAT-settled-deposit']"/>:</para>

    <spacer length="0.2cm"/>
    <blockTable colWidths="3.4cm,3.4cm,1.4cm,2.8cm,3.4cm,3.4cm" repeatRows="2" style="tbl_advance_payment">
      <tr>
        <td><xsl:value-of select="$loc/str[@name='Invoice number']"/></td>
        <td><xsl:value-of select="$loc/str[@name='CZK draw']"/></td>
        <td><xsl:value-of select="$loc/str[@name='VAT %']"/></td>
        <td><xsl:value-of select="$loc/str[@name='VAT']"/></td>
        <td><xsl:value-of select="$loc/str[@name='Deposit balance CZK']"/></td>
        <td><xsl:value-of select="$loc/str[@name='Deposit Total']"/></td>
      </tr>
      <tr>
        <td></td>
        <td></td>
        <td></td>
        <td></td>
        <td><xsl:value-of select="$loc/str[@name='no VAT']"/></td>
        <td><xsl:value-of select="$loc/str[@name='with VAT']"/></td>
      </tr>
    <xsl:apply-templates select="applied_invoices" />
    </blockTable>

</xsl:template>

<xsl:template match="applied_invoices">
    <xsl:for-each select="consumed">
    <xsl:sort select="number" order="descending" data-type="number" />
    <tr>
        <td><xsl:value-of select='number' /></td>
        <td><xsl:value-of select='format-number(price, "### ##0.00", "CZK")' /></td>
        <td><xsl:value-of select='format-number(vat_rate, "#0")' /></td>
        <td><xsl:value-of select='format-number(vat, "### ##0.00", "CZK")' /></td>
        <td><xsl:value-of select='format-number(balance, "### ##0.00", "CZK")' /></td>
        <td><xsl:value-of select='format-number(total_with_vat, "### ##0.00", "CZK")' /></td>
    </tr>
    </xsl:for-each>
</xsl:template>

<xsl:template match="appendix">
    <pageBreak/>
    <blockTable colWidths="1.3cm,2cm,5.6cm,2.1cm,1.8cm,1.8cm,1.2cm,2cm" repeatRows="2" style="appendix">
    <tr>
        <td><xsl:value-of select="$loc/str[@name='Change']"/></td>
        <td><xsl:value-of select="$loc/str[@name='Realized']"/></td>
        <td><xsl:value-of select="$loc/str[@name='Domain']"/></td>
        <td><xsl:value-of select="$loc/str[@name='Service to']"/></td>
        <td><xsl:value-of select="$loc/str[@name='Number']"/></td>
        <td><xsl:value-of select="$loc/str[@name='Price']"/></td>
        <td><xsl:value-of select="$loc/str[@name='Vat_part1']"/></td>
        <td><xsl:value-of select="$loc/str[@name='Total']"/></td>
    </tr>
    <tr>
        <td></td>
        <td></td>
        <td></td>
        <td></td>
        <td></td>
        <td><xsl:value-of select="$loc/str[@name='free of tax']"/></td>
        <td><xsl:value-of select="$loc/str[@name='Vat_part2']"/></td>
        <td><xsl:value-of select="$loc/str[@name='free of tax']"/></td>
    </tr>
    <xsl:apply-templates select="items" />
    </blockTable>
    <blockTable colWidths="1.3cm,2cm,5.6cm,2.1cm,1.8cm,1.8cm,1.2cm,2cm" style="sumarize_items">
    <xsl:apply-templates select="sumarize_items" />
    </blockTable>
</xsl:template>

<xsl:template match="items">
    <xsl:for-each select="item">
    <xsl:sort select="timestamp" />
    <xsl:sort select="subject" />
    <xsl:sort select="code" />

    <xsl:choose>
        <xsl:when test="string-length(subject) > 38">
            <xsl:call-template name="item-two-lines"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="item-one-line"/>
        </xsl:otherwise>
    </xsl:choose>
    </xsl:for-each>

</xsl:template>

<xsl:template name="item-one-line">
        <tr>
            <td><xsl:value-of select='code' /></td>
            <td><xsl:call-template name="local_date"><xsl:with-param name="sdt" select="timestamp" /></xsl:call-template></td>
            <td><xsl:value-of select='subject' /></td>
            <td><xsl:call-template name="local_date"><xsl:with-param name="sdt" select="expiration" /></xsl:call-template></td>
            <td><xsl:value-of select='count' /></td>
            <td><xsl:value-of select='format-number(price, "### ##0.00", "CZK")' /></td>
            <td><xsl:value-of select='vat_rate' />%</td>
            <td><xsl:value-of select='format-number(total, "### ##0.00", "CZK")' /></td>
        </tr>
</xsl:template>

<xsl:template name="item-two-lines">
        <tr>
            <td><xsl:value-of select='code' /></td>
            <td><xsl:call-template name="local_date"><xsl:with-param name="sdt" select="timestamp" /></xsl:call-template></td>
            <td><xsl:value-of select='subject' /></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
        </tr>
        <tr>
            <td></td>
            <td></td>
            <td></td>
            <td><xsl:call-template name="local_date"><xsl:with-param name="sdt" select="expiration" /></xsl:call-template></td>
            <td><xsl:value-of select='count' /></td>
            <td><xsl:value-of select='format-number(price, "### ##0.00", "CZK")' /></td>
            <td><xsl:value-of select='vat_rate' />%</td>
            <td><xsl:value-of select='format-number(total, "### ##0.00", "CZK")' /></td>
        </tr>
</xsl:template>


<xsl:template match="sumarize_items">
<tr>
    <td><xsl:value-of select="$loc/str[@name='Total']"/></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td><xsl:value-of select='format-number(total, "### ##0.00", "CZK")' /></td>
</tr>
</xsl:template>

</xsl:stylesheet>
