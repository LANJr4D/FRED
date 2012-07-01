<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
<!ENTITY SPACE "<xsl:text xmlns:xsl='http://www.w3.org/1999/XSL/Transform'> </xsl:text>">
]>
<!-- 

This template serves as pattern for transfer of public_request.xml record into PDF. 
Tato šablona slouží pro převod public_request.xml záznamu do PDF.
Create: Aleš Doležal <ales.dolezal@nic.cz>; 20.5.2008,
based on template created by Zdeněk Böhm <zdenek.bohm@nic.cz>; 1.2.2007, 12.2.2007

There is used a logo (file cz_nic_logo.jpg), which is saved in a folder templates/
together with this template. It is neccesity to set up path properly, if the template isn't called
from script folder (fred2pdf/trunk):

(There have to be two hyphens before stringparam.)
$xsltproc -stringparam srcpath enum/fred2pdf/trunk/templates/ -stringparam lang en enum/fred2pdf/trunk/templates/auth_info.xsl enum/fred2pdf/trunk/examples/auth_info.xml
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="xml" encoding="utf-8" />

    <xsl:param name="srcpath" select="'templates/'" />
    <xsl:param name="lang" select="'en'" />
    
    <xsl:template name="getstr">
        <xsl:param name="str"/>
        <xsl:variable name="type"><xsl:value-of select="current()/type"/></xsl:variable>
        <xsl:choose>
            <xsl:when test="$type = 1"><xsl:value-of select="document(concat('authinfo_request_', $lang, '.xml'))/strings/str[@name=$str]"/></xsl:when>
            <xsl:when test="$type = 2"><xsl:value-of select="document(concat('block_transfer_', $lang, '.xml'))/strings/str[@name=$str]"/></xsl:when>
            <xsl:when test="$type = 3"><xsl:value-of select="document(concat('unblock_transfer_', $lang, '.xml'))/strings/str[@name=$str]"/></xsl:when>
            <xsl:when test="$type = 4"><xsl:value-of select="document(concat('block_update_', $lang, '.xml'))/strings/str[@name=$str]"/></xsl:when>
            <xsl:when test="$type = 5"><xsl:value-of select="document(concat('unblock_update_', $lang, '.xml'))/strings/str[@name=$str]"/></xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="getstr2">
        <xsl:param name="str"/>
        <xsl:variable name="type"><xsl:value-of select="current()/type"/></xsl:variable>
        <xsl:variable name="type_id"><xsl:value-of select="current()/handle/@type"/></xsl:variable>
        <xsl:choose>
            <xsl:when test="$type = 1 and $type_id = 1"><xsl:value-of select="document(concat('authinfo_request_', $lang, '.xml'))/strings/str[@name=concat($str, '_contact')]"/></xsl:when>
            <xsl:when test="$type = 2 and $type_id = 1"><xsl:value-of select="document(concat('block_transfer_', $lang, '.xml'))/strings/str[@name=concat($str, '_contact')]"/></xsl:when>
            <xsl:when test="$type = 3 and $type_id = 1"><xsl:value-of select="document(concat('unblock_transfer_', $lang, '.xml'))/strings/str[@name=concat($str, '_contact')]"/></xsl:when>
            <xsl:when test="$type = 4 and $type_id = 1"><xsl:value-of select="document(concat('block_update_', $lang, '.xml'))/strings/str[@name=concat($str, '_contact')]"/></xsl:when>
            <xsl:when test="$type = 5 and $type_id = 1"><xsl:value-of select="document(concat('unblock_update_', $lang, '.xml'))/strings/str[@name=concat($str, '_contact')]"/></xsl:when>

            <xsl:when test="$type = 1 and $type_id = 2"><xsl:value-of select="document(concat('authinfo_request_', $lang, '.xml'))/strings/str[@name=concat($str, '_nsset')]"/></xsl:when>
            <xsl:when test="$type = 2 and $type_id = 2"><xsl:value-of select="document(concat('block_transfer_', $lang, '.xml'))/strings/str[@name=concat($str, '_nsset')]"/></xsl:when>
            <xsl:when test="$type = 3 and $type_id = 2"><xsl:value-of select="document(concat('unblock_transfer_', $lang, '.xml'))/strings/str[@name=concat($str, '_nsset')]"/></xsl:when>
            <xsl:when test="$type = 4 and $type_id = 2"><xsl:value-of select="document(concat('block_update_', $lang, '.xml'))/strings/str[@name=concat($str, '_nsset')]"/></xsl:when>
            <xsl:when test="$type = 5 and $type_id = 2"><xsl:value-of select="document(concat('unblock_update_', $lang, '.xml'))/strings/str[@name=concat($str, '_nsset')]"/></xsl:when>

            <xsl:when test="$type = 1 and $type_id = 3"><xsl:value-of select="document(concat('authinfo_request_', $lang, '.xml'))/strings/str[@name=concat($str, '_domain')]"/></xsl:when>
            <xsl:when test="$type = 2 and $type_id = 3"><xsl:value-of select="document(concat('block_transfer_', $lang, '.xml'))/strings/str[@name=concat($str, '_domain')]"/></xsl:when>
            <xsl:when test="$type = 3 and $type_id = 3"><xsl:value-of select="document(concat('unblock_transfer_', $lang, '.xml'))/strings/str[@name=concat($str, '_domain')]"/></xsl:when>
            <xsl:when test="$type = 4 and $type_id = 3"><xsl:value-of select="document(concat('block_update_', $lang, '.xml'))/strings/str[@name=concat($str, '_domain')]"/></xsl:when>
            <xsl:when test="$type = 5 and $type_id = 3"><xsl:value-of select="document(concat('unblock_update_', $lang, '.xml'))/strings/str[@name=concat($str, '_domain')]"/></xsl:when>

            <xsl:when test="$type = 1 and $type_id = 4"><xsl:value-of select="document(concat('authinfo_request_', $lang, '.xml'))/strings/str[@name=concat($str, '_keyset')]"/></xsl:when>
            <xsl:when test="$type = 2 and $type_id = 4"><xsl:value-of select="document(concat('block_transfer_', $lang, '.xml'))/strings/str[@name=concat($str, '_keyset')]"/></xsl:when>
            <xsl:when test="$type = 3 and $type_id = 4"><xsl:value-of select="document(concat('unblock_transfer_', $lang, '.xml'))/strings/str[@name=concat($str, '_keyset')]"/></xsl:when>
            <xsl:when test="$type = 4 and $type_id = 4"><xsl:value-of select="document(concat('block_update_', $lang, '.xml'))/strings/str[@name=concat($str, '_keyset')]"/></xsl:when>
            <xsl:when test="$type = 5 and $type_id = 4"><xsl:value-of select="document(concat('unblock_update_', $lang, '.xml'))/strings/str[@name=concat($str, '_keyset')]"/></xsl:when>
        </xsl:choose>
    </xsl:template>


    <xsl:template name="authinfo">
        <para>
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_1</xsl:with-param></xsl:call-template>
            &SPACE;
            <xsl:call-template name="getstr2"><xsl:with-param name="str">re</xsl:with-param></xsl:call-template>
            &SPACE;
            <b><xsl:value-of select="handle" /></b>
            &SPACE;
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_2</xsl:with-param></xsl:call-template>
            &SPACE;
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_3</xsl:with-param></xsl:call-template>
            &SPACE;
            <b><xsl:value-of select="date" /></b>
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_4</xsl:with-param></xsl:call-template>
            &SPACE;
            <b><xsl:value-of select="id" /></b>
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_5</xsl:with-param></xsl:call-template>
            &SPACE;
            <b><xsl:value-of select="replymail" /></b>.
        </para>
        <spacer length="0.6cm"/>
        <para>
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_6</xsl:with-param></xsl:call-template>
        </para>
    </xsl:template>

    <xsl:template name="unblock">
        <para>
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_1</xsl:with-param></xsl:call-template>
            &SPACE;
            <xsl:call-template name="getstr2"><xsl:with-param name="str">re</xsl:with-param></xsl:call-template>
            &SPACE;
            <b><xsl:value-of select="handle"/></b>
            &SPACE;
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_2</xsl:with-param></xsl:call-template>
            &SPACE;
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_3</xsl:with-param></xsl:call-template>
            &SPACE;
            <b><xsl:value-of select="date"/></b>
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_4</xsl:with-param></xsl:call-template>
            &SPACE;
            <b><xsl:value-of select="id"/></b>
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_5</xsl:with-param></xsl:call-template>
        </para>
        <spacer length="0.6cm"/>
        <para>
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_6</xsl:with-param></xsl:call-template>
        </para>
    </xsl:template>

    <xsl:template name="block">
        <para>
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_1</xsl:with-param></xsl:call-template>
            &SPACE;
            <xsl:call-template name="getstr2"><xsl:with-param name="str">re</xsl:with-param></xsl:call-template>
            &SPACE;
            <b><xsl:value-of select="handle"/></b>
            &SPACE;
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_2</xsl:with-param></xsl:call-template>
            &SPACE;
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_3</xsl:with-param></xsl:call-template>
            &SPACE;
            <b><xsl:value-of select="date"/></b>
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_4</xsl:with-param></xsl:call-template>
            &SPACE;
            <b><xsl:value-of select="id"/></b>
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_5</xsl:with-param></xsl:call-template>
            &SPACE;
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_6</xsl:with-param></xsl:call-template>
            &SPACE;
            <xsl:call-template name="getstr2"><xsl:with-param name="str">re</xsl:with-param></xsl:call-template>
            &SPACE;
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_7</xsl:with-param></xsl:call-template>
            &SPACE;
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_8</xsl:with-param></xsl:call-template>
        </para>
        <spacer length="0.6cm"/>
        <para>
            <xsl:call-template name="getstr"><xsl:with-param name="str">line_9</xsl:with-param></xsl:call-template>
        </para>
    </xsl:template>

    <xsl:template match="/enum_whois/public_request">

        <xsl:if test="not($lang='cs' or $lang='en')">
            <xsl:message terminate="yes">Parameter 'lang' is invalid. Available values are: cs, en</xsl:message>
        </xsl:if>

<document>
    <!--TODO i cannot change title parameter in template element-->
    <template pageSize="(21cm, 29.7cm)" leftMargin="2.0cm" rightMargin="2.0cm" topMargin="2.0cm" bottomMargin="2.0cm" 
        title="public request" author="CZ.NIC">

    <!-- <template pageSize="(21cm, 29.7cm)" leftMargin="2.0cm" rightMargin="2.0cm" topMargin="2.0cm" bottomMargin="2.0cm"  -->
        <!-- title="{document(concat('authinfo_request_', $lang, '.xml'))/strings/str[@name='head']}" author="CZ.NIC"> -->

        <pageTemplate id="main">
            <pageGraphics>

                <!-- Page header -->
                <image file="{$srcpath}cz_nic_logo.jpg" x="2.3cm" y="25cm" width="4.5cm" />
                <stroke color="#bab198"/>
                <lineMode width="0.2cm"/>
                <lines>2.5cm 24.4cm 18.5cm 24.4cm</lines>
                <lineMode width="1"/>
                <fill color="#a8986d"/>
                <setFont name="Times-Bold" size="12"/>
                <drawString x="2.5cm" y="23.4cm" color="#a8986d">
                    <xsl:call-template name="getstr"><xsl:with-param name="str">head</xsl:with-param></xsl:call-template>
                </drawString>
                <fill color="black"/>
                <frame id="body" x1="2.3cm" y1="10cm" width="16.6cm" height="13cm" showBoundary="0" />

                <!-- Page footer -->
                <stroke color="#c0c0c0"/>
                <lines>2.5cm 8.6cm 18.5cm 8.6cm</lines>
                <setFont name="Times-Roman" size="8"/>
                <drawString x="2.5cm" y="8cm">
                    <xsl:call-template name="getstr"><xsl:with-param name="str">footer_1</xsl:with-param></xsl:call-template>
                </drawString>
                <drawString x="2.5cm" y="2.2cm">
                    <xsl:call-template name="getstr"><xsl:with-param name="str">footer_2</xsl:with-param></xsl:call-template>
                </drawString>
                <drawString x="2.5cm" y="1.8cm">
                    <xsl:call-template name="getstr"><xsl:with-param name="str">footer_3</xsl:with-param></xsl:call-template>
                </drawString>
                <setFont name="Times-Bold" size="12"/>
                <drawString x="11.5cm" y="5.5cm">Zákaznická podpora</drawString>
                <drawString x="11.5cm" y="4.7cm">CZ.NIC, z. s. p. o. Americká 23</drawString>
                <drawString x="11.5cm" y="3.9cm">120 00 Praha 2</drawString>

                <!-- Folder marks -->
                <stroke color="black"/>
                <lines>0.5cm 10.2cm 1cm 10.2cm</lines>
                <lines>20cm 10.2cm 20.5cm 10.2cm</lines>

                <lines>0.5cm 20.2cm 1cm 20.2cm</lines>
                <lines>20cm 20.2cm 20.5cm 20.2cm</lines>
            </pageGraphics>
        </pageTemplate>
    </template>
    <stylesheet>
        <paraStyle name="address" fontName="Times-Italic" fontSize="8" leftIndent="1.4cm" />
        <paraStyle name="footer" fontSize="8" />
    </stylesheet>
    <story>
        <para>
            <xsl:call-template name="getstr"><xsl:with-param name="str">subject</xsl:with-param></xsl:call-template>
            &SPACE;
            <xsl:call-template name="getstr2"><xsl:with-param name="str">re</xsl:with-param></xsl:call-template>
            &SPACE;
            <xsl:value-of select="handle" />.
        </para>
        <spacer length="0.6cm"/>
        <xsl:choose>
            <xsl:when test="type = 1"><xsl:call-template name="authinfo"/></xsl:when>
            <xsl:when test="type = 2 or type = 4"><xsl:call-template name="block"/></xsl:when>
            <xsl:when test="type = 3 or type = 5"><xsl:call-template name="unblock"/></xsl:when>
        </xsl:choose>
        <spacer length="1.6cm"/>
        <para>
        ...........................................................................
        </para>
    </story>
</document>
    </xsl:template>
</xsl:stylesheet>
