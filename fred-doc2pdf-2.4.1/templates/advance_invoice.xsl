<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
<!ENTITY SPACE "<xsl:text xmlns:xsl='http://www.w3.org/1999/XSL/Transform'> </xsl:text>">
]>
<!-- 
Usage:
$ xsltproc -stringparam srcpath yourpath/templates/ -stringparam lang en yourpath/templates/advance_invoice.xsl yourpath/examples/advance_invoice.xml
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

        <image file="{$srcpath}white-balls.png" x="10cm" y="26.8cm" width="2cm"/>

        <fill color="white" />
        <setFont name="Times-Roman" size="14"/>
        <drawRightString x="19.3cm" y="27.9cm">
            <xsl:choose>
                <xsl:when test="number(delivery/sumarize/total)&lt;0">
                    <xsl:value-of select="$loc/str[@name='Tax credit']"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$loc/str[@name='Advance Payment Request / Vat voucher']"/>
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
        <drawRightString x="19.3cm" y="19.2cm"><xsl:call-template name="local_date"><xsl:with-param name="sdt" select="payment/advance_payment_date" /></xsl:call-template></drawRightString>

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

</template>

<stylesheet>
    <paraStyle fontSize="9"/>
    <blockTableStyle id="tbl_delivery">
      <blockFont name="Times-Roman" start="0,0" stop="-1,-1" size="9"/>
      <lineStyle kind="LINEABOVE" start="0,0"  stop="-1,0"  thickness="0.5" colorName="black"/>
      <lineStyle kind="LINEBELOW" start="0,-1" stop="-1,-1" thickness="0.5" colorName="black"/>
      <blockAlignment value="RIGHT" start="1,0" stop="1,-1"/>
      <blockFont name="Times-Bold" start="0,-1" stop="-1,-1"/>
      <blockFont name="Times-Bold" start="0,0" stop="-1,0"/>
      <blockAlignment value="RIGHT" start="1,0" stop="-1,-1"/>
      <blockLeftPadding length="0" start="0,0" stop="0,-1" />
      <blockRightPadding length="0" start="-1,0" stop="-1,-1" />
      <blockTopPadding length="0" start="0,1" stop="-1,-2" />
      <blockBottomPadding length="0" start="0,0" stop="-1,-2" />
      <blockTopPadding length="0.3cm" start="0,0" stop="-1,0" />
      <blockTopPadding length="0.3cm" start="0,-1" stop="-1,-1" />
      <blockBottomPadding length="0.2cm" start="0,-1" stop="-1,-1" />
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
<para>
    <xsl:choose>
        <xsl:when test="number(delivery/sumarize/total)&lt;0">
            <xsl:value-of select="$loc/str[@name='Tax credit text']"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="payment/tax_credit_number"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$loc/str[@name='Voucher-for-call-VAT']"/>
        </xsl:otherwise>        
    </xsl:choose>
    
<xsl:if test="client/vat_not_apply = 1">
    &SPACE;<xsl:value-of select="$loc/str[@name='Insurance-by-law-and-VAT-liability']"/>
</xsl:if>
</para>

<xsl:apply-templates select="delivery" />

</story>

</document>
</xsl:template>

<xsl:template match="delivery">
<spacer length="0.4cm"/>
<blockTable colWidths="6.4cm,1.5cm,3.3cm,3.3cm,3.3cm" style="tbl_delivery">
<tr>
    <td><xsl:value-of select="$loc/str[@name='Sum']"/>:</td>
    <td><xsl:value-of select="$loc/str[@name='VAT %']"/></td>
    <td><xsl:value-of select="$loc/str[@name='Tax base']"/></td>
    <td><xsl:value-of select="$loc/str[@name='VAT CZK']"/></td>
    <td><xsl:value-of select="$loc/str[@name='Total CZK']"/></td>
</tr>
<xsl:apply-templates />
</blockTable>
</xsl:template>

<xsl:template match="vat_rates">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="entry">
<tr>
    <td></td>
    <td><xsl:value-of select='format-number(vatperc, "#0")' />%</td>
    <td><xsl:value-of select='format-number(basetax, "### ##0.00", "CZK")' /></td>
    <td><xsl:value-of select='format-number(vat, "### ##0.00", "CZK")' /></td>
    <td><xsl:value-of select='format-number(total, "### ##0.00", "CZK")' /></td>
</tr>
</xsl:template>

<xsl:template match="sumarize">
<tr>
    <td><xsl:value-of select="$loc/str[@name='To be paid']"/>:</td>
    <td></td>
    <td></td>
    <td></td>
    <td><xsl:value-of select='format-number(to_be_paid, "### ##0.00", "CZK")' /></td>
</tr>
</xsl:template>

</xsl:stylesheet>
