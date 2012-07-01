<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:date="http://exslt.org/dates-and-times"
 extension-element-prefixes="date">
 <xsl:output method="xml" encoding="windows-1250" />

 <xsl:template name="local_date">
  <xsl:param name="sdt" />
  <xsl:if test="$sdt">
   <xsl:value-of select="substring($sdt,9,2)" />
   <xsl:text>.</xsl:text>
   <xsl:value-of select="substring($sdt,6,2)" />
   <xsl:text>.</xsl:text>
   <xsl:value-of select="substring($sdt,1,4)" />
  </xsl:if>
 </xsl:template>

 <xsl:template name="invoice_number">
  <xsl:param name="number" select="payment/invoice_number" />
  <xsl:choose>
   <xsl:when
    test="substring($number,0,5)='2307' or substring($number,0,5)='2407'">
    <xsl:value-of
     select="concat(substring($number,0,5),substring($number,6))" />
   </xsl:when>
   <xsl:otherwise>
    <xsl:value-of select="$number" />
   </xsl:otherwise>
  </xsl:choose>
 </xsl:template>

 <xsl:template name="invoice_group">
  <xsl:value-of select="substring(payment/invoice_number,0,4)" />
 </xsl:template>

 <xsl:variable name="pk_dph_19" select="1" />
 <xsl:variable name="pk_dph_20" select="$pk_dph_19 + 1" />
 <xsl:variable name="pk_dph_0" select="$pk_dph_20 + 1" />
 <xsl:variable name="pk_payment_type" select="$pk_dph_0 + 1" />
 <xsl:variable name="pk_stred" select="$pk_payment_type + 1" />
 <xsl:variable name="pk_bank_spoj" select="$pk_stred + 1" />
 <xsl:variable name="pk_skup" select="$pk_bank_spoj + 1" />
 <xsl:variable name="pk_cz_currency" select="$pk_skup + 1" />
 <xsl:variable name="pk_bank" select="'BANK'" />
 <xsl:variable name="pk_maj" select="'MAJ'" />
 <xsl:variable name="pk_period" select="0" />
 <xsl:variable name="pk_cisorg" select="0 + count(/list/invoice)" />
 <xsl:variable name="pk_cznic" select="'CZNIC'" />
 <xsl:variable name="pk_zeme" select="'ZEME'" />
 <xsl:variable name="pk_dic" select="0" />
 <xsl:variable name="pk_inv_groups" select="0" />

 <xsl:template name="pk_sazba_dph">
  <xsl:param name="sazba" select="''" />
  <xsl:choose>
   <xsl:when test="$sazba=0">
    <xsl:text>FK_</xsl:text>
    <xsl:value-of select="$pk_dph_0" />
   </xsl:when>
   <xsl:when test="$sazba=19">
    <xsl:text>FK_</xsl:text>
    <xsl:value-of select="$pk_dph_19" />
   </xsl:when>
   <xsl:when test="$sazba=20">
    <xsl:text>FK_</xsl:text>
    <xsl:value-of select="$pk_dph_20" />
   </xsl:when>
   <xsl:otherwise>
    <xsl:message terminate = "yes">MISSING VAT RATE</xsl:message>
   </xsl:otherwise>
  </xsl:choose>
 </xsl:template>

 <xsl:key name="invoices-by-group" match="/list/invoice | /invoice"
  use="substring(payment/invoice_number,0,4)" />

 <xsl:key name="invoices-by-client" match="/list/invoice | /invoice"
  use="client/id" />

 <xsl:key name="adv-inv-by-number"
  match="/list/invoice/advance_payment/applied_invoices/consumed | 
              /invoice/advance_payment/applied_invoices/consumed"
  use="number" />

 <xsl:key name="entries-by-year"
  match="/list/invoice/delivery/vat_rates/entry/years/entry |
              /invoice/delivery/vat_rates/entry/years/entry"
  use="year" />

 <!-- support for two input formats, input xml format can have structure
  either /invoice or /list/invoice -->
 <xsl:template match="/">
  <xsl:choose>
   <xsl:when test="count(list)">
    <!-- /list/invoice = descent one level down in input xml tree -->
    <xsl:apply-templates />
   </xsl:when>
   <xsl:otherwise>
    <!-- /invoice = call template on root node -->
    <xsl:call-template name="list" />
   </xsl:otherwise>
  </xsl:choose>
 </xsl:template>

 <xsl:template match="list">
  <!-- call template on list node -->
  <xsl:call-template name="list" />
 </xsl:template>

 <!-- main template, must ve called in context of group of invoice nodes -->
 <xsl:template name="list">
  <xsl:variable name="now" select="substring(date:date-time(),1,19)" />
  <HeliosIQ_1>
   <header>
    <delivery>
     <message>
      <messageID>
       <xsl:text>FaV</xsl:text>
       <xsl:call-template name='invoice_number'>
        <xsl:with-param name='number' select="payment/invoice_number" />
       </xsl:call-template>
       <xsl:text>.XML</xsl:text>
      </messageID>
      <sent>
       <xsl:value-of select="$now" />
      </sent>
     </message>
     <to>
      <address>C:\</address>
     </to>
     <from>
      <address>CZ.NIC, z.s.p.o.</address>
     </from>
    </delivery>
    <manifest>
     <document>
      <name>PohyboveDoklady</name>
      <description>
       <xsl:text>internal-format-HELIOS:lcs_cz:PohyboveDoklady</xsl:text>
      </description>
      <!-- <version>010020070611</version>  -->
      <version>020020110105</version>
     </document>
    </manifest>
   </header>
   <body>
    <xsl:for-each select="invoice">
     <PohyboveDoklady>
      <cisloDokladu>
       <xsl:call-template name='invoice_number' />
      </cisloDokladu>
      <DruhPohybuZbo>13</DruhPohybuZbo>
      <TabDokladyZbozi>
       <PopisDodavky>
        <xsl:text>vyuctovani domeny</xsl:text>
       </PopisDodavky>
       <ZaokrouhleniFak>0</ZaokrouhleniFak>
       <ZaokrouhleniFakVal>0</ZaokrouhleniFakVal>
       <SazbaDPH>
        <xsl:call-template name="pk_sazba_dph">
         <xsl:with-param name="sazba"
          select="delivery/vat_rates/entry[position()=1]/vatperc" />
        </xsl:call-template>
       </SazbaDPH>
       <SazbaDPH1>
        <xsl:call-template name="pk_sazba_dph">
         <xsl:with-param name="sazba"
          select="delivery/vat_rates/entry[position()=1]/vatperc" />
        </xsl:call-template>
       </SazbaDPH1>
       <xsl:if test="count(advance_payment)">
        <Zaloha>
         <xsl:value-of select="sum(delivery/vat_rates/entry/total)" />
        </Zaloha>
        <ZalohaVal>
         <xsl:value-of select="sum(delivery/vat_rates/entry/total)" />
        </ZalohaVal>
       </xsl:if>
       <CbezDPH1>
        <xsl:value-of select="delivery/vat_rates/entry[position()=1]/basetax" />
       </CbezDPH1>
       <CsDPH1>
        <xsl:value-of select="delivery/vat_rates/entry[position()=1]/total" />
       </CsDPH1>
       <CbezDPH1Val>
        <xsl:value-of select="delivery/vat_rates/entry[position()=1]/basetax" />
       </CbezDPH1Val>
       <CsDPH1Val>
        <xsl:value-of select="delivery/vat_rates/entry[position()=1]/total" />
       </CsDPH1Val>
       <DatPorizeni>
        <xsl:choose>
         <xsl:when test="count(payment/tax_point)">
          <xsl:value-of select="payment/tax_point" />
         </xsl:when>
         <xsl:when test="count(payment/advance_payment_date)">
          <xsl:value-of select="payment/advance_payment_date" />
         </xsl:when>
        </xsl:choose>
        <xsl:text> 00:00:00</xsl:text>
       </DatPorizeni>
       <Splatnost>
        <xsl:value-of select="payment/invoice_date" />
        <xsl:text> 00:00:00</xsl:text>
       </Splatnost>
       <xsl:if test="count(payment/tax_point)">
        <DUZP>
         <xsl:value-of select="payment/tax_point" />
        </DUZP>
       </xsl:if>
       <xsl:if test="count(payment/advance_payment_date)">
        <DUZP>
         <xsl:value-of select="payment/advance_payment_date" />
        </DUZP>
       </xsl:if>
       <DatPovinnostiFa>
        <xsl:text>2007-11-07 00:00:00</xsl:text>
       </DatPovinnostiFa>
       <UKod>
        <xsl:text>FK_UKOD_</xsl:text>
        <xsl:call-template name="invoice_group" />
       </UKod>
       <FormaUhrady>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_payment_type" />
       </FormaUhrady>
       <xsl:if test="count(payment/period_from)">
        <IdObdobiStavu>
         <xsl:text>FK_PER_</xsl:text>
         <xsl:value-of select="$pk_period + position()" />
        </IdObdobiStavu>
       </xsl:if>
       <IDBankSpoj>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_bank_spoj" />
       </IDBankSpoj>
       <CisloOrg>
        <xsl:text>FK_CL_</xsl:text>
        <xsl:value-of select="client/id" />
       </CisloOrg>
       <RadaDokladu>
        <xsl:text>FK_DDZ_</xsl:text>
        <xsl:call-template name="invoice_group" />
       </RadaDokladu>
       <PoziceZaokrDPH>1</PoziceZaokrDPH>
       <DIC>
        <xsl:text>FK_DIC_</xsl:text>
        <xsl:value-of select="client/id" />
       </DIC>
       <Mena>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_cz_currency" />
       </Mena>
       <xsl:if test="count(payment/tax_point)">
        <IDReal>
         <xsl:text>FK_ZALFAK_</xsl:text>
         <xsl:value-of select="payment/invoice_number" />
        </IDReal>
       </xsl:if>
       <PoziceZaokrDPHHla>1</PoziceZaokrDPHHla>
       <HraniceZaokrDPHHla>2</HraniceZaokrDPHHla>
       <ZaokrNaPadesat>0</ZaokrNaPadesat>
       <!-- TODO: check this quick fix -->
       <xsl:if test="count(advance_payment)=0">
	       <TabOZSumaceCen>
	        <Poradi>1</Poradi> <!-- unknown value -->
	        <SazbaDPH>
	         <xsl:call-template name="pk_sazba_dph">
	          <xsl:with-param name="sazba"
	           select="delivery/vat_rates/entry[position()=1]/vatperc" />
	         </xsl:call-template>
	        </SazbaDPH>
	        <CbezDPHOZ>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/basetax" />
	        </CbezDPHOZ>
	        <CsDPHOZ>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/total" />
	        </CsDPHOZ>
	        <CbezDPHValOZ>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/basetax" />
	        </CbezDPHValOZ>
	        <CsDPHValOZ>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/total" />
	        </CsDPHValOZ>
	       </TabOZSumaceCen>
       </xsl:if>
      </TabDokladyZbozi>
      <xsl:if test="count(advance_payment)=0">
	      <TabOZTxtPol>
	       <Poradi>1</Poradi>
	       <MJ>ks</MJ>
	       <SazbaDPH>
	         <xsl:call-template name="pk_sazba_dph">
	          <xsl:with-param name="sazba"
	           select="delivery/vat_rates/entry[position()=1]/vatperc" />
	         </xsl:call-template>
	       </SazbaDPH>
	       <Mnozstvi>1</Mnozstvi>
	       <JCbezDaniKC>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/basetax" />
	       </JCbezDaniKC>
	       <JCsDPHKc>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/total" />
	       </JCsDPHKc>
	       <JCbezDaniKcPoS>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/basetax" />
	       </JCbezDaniKcPoS>
	       <JCsDPHKcPoS>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/total" />
	       </JCsDPHKcPoS>
	       <JCbezDaniVal>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/basetax" />
	       </JCbezDaniVal>
	       <JCsDPHVal>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/total" />
	       </JCsDPHVal>
	       <JCbezDaniValPoS>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/basetax" />
	       </JCbezDaniValPoS>
	       <JCsDPHValPoS>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/total" />
	       </JCsDPHValPoS>
	       <CCbezDaniKC>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/basetax" />
	       </CCbezDaniKC>
	       <CCsDPHKc>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/total" />
	       </CCsDPHKc>
	       <CCbezDaniKcPoS>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/basetax" />
	       </CCbezDaniKcPoS>
	       <CCsDPHKcPoS>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/total" />
	       </CCsDPHKcPoS>
	       <CCbezDaniVal>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/basetax" />
	       </CCbezDaniVal>
	       <CCsDPHVal>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/total" />
	       </CCsDPHVal>
	       <CCbezDaniValPoS>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/basetax" />
	       </CCbezDaniValPoS>
	       <CCsDPHValPoS>
	         <xsl:value-of select="delivery/vat_rates/entry[position()=1]/total" />
	       </CCsDPHValPoS>
	      </TabOZTxtPol>
      </xsl:if>
      <xsl:for-each select='advance_payment/applied_invoices/consumed'>
       <TabDoplnkovePol>
        <Auto>4</Auto>
        <Cislo>
         <xsl:value-of select="position()" />
        </Cislo>
        <SazbaDPH>
         <xsl:call-template name="pk_sazba_dph">
          <xsl:with-param name="sazba" select="vat_rate" />
         </xsl:call-template>
        </SazbaDPH>
        <KorekceZakladuDane>
         <xsl:value-of select="-price" />
        </KorekceZakladuDane>
        <KorekceDane>
         <xsl:value-of select="-vat" />
        </KorekceDane>
        <KorekceZakladuDaneVal>
         <xsl:value-of select="-total" />
        </KorekceZakladuDaneVal>
        <KorekceDaneVal>
         <xsl:value-of select="-total_vat" />
        </KorekceDaneVal>
        <ParovaciZnak>
         <xsl:call-template name='invoice_number'>
          <xsl:with-param name='number' select="number" />
         </xsl:call-template>
        </ParovaciZnak>
       </TabDoplnkovePol>
      </xsl:for-each>
      <xsl:for-each select='delivery/vat_rates/entry/years/entry'>
       <TabPohybyZbozi>
        <RegCis>
         <xsl:text>0</xsl:text>
         <xsl:value-of select='year' />
        </RegCis>
        <Nazev1>
         <xsl:text>Výnosy roku </xsl:text>
         <xsl:value-of select='year' />
        </Nazev1>
        <MJEvidence>
         <xsl:text>FK_</xsl:text>
         <xsl:value-of select="$pk_maj" />
        </MJEvidence>
        <MJ>
         <xsl:text>FK_</xsl:text>
         <xsl:value-of select="$pk_maj" />
        </MJ>
        <SazbaDPH>
         <xsl:call-template name="pk_sazba_dph">
          <xsl:with-param name="sazba" select="../../vatperc" />
         </xsl:call-template>
        </SazbaDPH>
        <MnOdebrane>0</MnOdebrane>
        <JCbezDaniKC>
         <xsl:value-of select='price' />
        </JCbezDaniKC>
        <JCsDPHKc>
         <xsl:value-of select='total' />
        </JCsDPHKc>
        <JCbezDaniVal>
         <xsl:value-of select='price' />
        </JCbezDaniVal>
        <JCsDPHVal>
         <xsl:value-of select='total' />
        </JCsDPHVal>
        <CCbezDaniKc>
         <xsl:value-of select='price' />
        </CCbezDaniKc>
        <CCsDPHKc>
         <xsl:value-of select='total' />
        </CCsDPHKc>
        <CCbezDaniVal>
         <xsl:value-of select='price' />
        </CCbezDaniVal>
        <CCsDPHVal>
         <xsl:value-of select='total' />
        </CCsDPHVal>
        <JCsSDKc>
         <xsl:value-of select='price' />
        </JCsSDKc>
        <JCsSDVal>
         <xsl:value-of select='price' />
        </JCsSDVal>
        <JCbezDaniKcPoS>
         <xsl:value-of select='price' />
        </JCbezDaniKcPoS>
        <JCsSDKcPoS>
         <xsl:value-of select='price' />
        </JCsSDKcPoS>
        <JCsDPHKcPoS>
         <xsl:value-of select='total' />
        </JCsDPHKcPoS>
        <JCbezDaniValPoS>
         <xsl:value-of select='price' />
        </JCbezDaniValPoS>
        <JCsSDValPoS>
         <xsl:value-of select='price' />
        </JCsSDValPoS>
        <JCsDPHValPoS>
         <xsl:value-of select='total' />
        </JCsDPHValPoS>
        <CCsSDKc>
         <xsl:value-of select='price' />
        </CCsSDKc>
        <CCsSDVal>
         <xsl:value-of select='price' />
        </CCsSDVal>
        <CCbezDaniKcPoS>
         <xsl:value-of select='price' />
        </CCbezDaniKcPoS>
        <CCsSDKcPoS>
         <xsl:value-of select='price' />
        </CCsSDKcPoS>
        <CCsDPHKcPoS>
         <xsl:value-of select='total' />
        </CCsDPHKcPoS>
        <CCbezDaniValPoS>
         <xsl:value-of select='price' />
        </CCbezDaniValPoS>
        <CCsSDValPoS>
         <xsl:value-of select='price' />
        </CCsSDValPoS>
        <CCsDPHValPoS>
         <xsl:value-of select='total' />
        </CCsDPHValPoS>
        <PrepMnozstvi>1</PrepMnozstvi>
        <MnozstviStorno>0</MnozstviStorno>
        <Mnozstvi>1</Mnozstvi>
        <Hmotnost>0</Hmotnost>
        <CCevidPozadovana>0</CCevidPozadovana>
        <MnOdebraneReal>0</MnOdebraneReal>
        <MnozstviStornoReal>0</MnozstviStornoReal>
        <CCevid>0</CCevid>
        <EvMnozstvi>0</EvMnozstvi>
        <EvStav>0</EvStav>
        <MnozstviReal>0</MnozstviReal>
        <DatPorizeni>
         <xsl:value-of select='payment/invoice_date' />
        </DatPorizeni>
        <NastaveniSlev>4681</NastaveniSlev>
        <DruhPohybuZbo>13</DruhPohybuZbo>
        <SkupZbo>
         <xsl:text>FK_</xsl:text>
         <xsl:value-of select='$pk_skup' />
        </SkupZbo>
        <IDZboSklad>
         <xsl:text>FK_SS_</xsl:text>
         <xsl:value-of select='year' />
        </IDZboSklad>
        <KJKontrolovat>1</KJKontrolovat>
        <KJSkontrolovano>1</KJSkontrolovano>
        <Mena>
         <xsl:text>FK_</xsl:text>
         <xsl:value-of select='$pk_cz_currency' />
        </Mena>
        <PrepocetMJSD>1</PrepocetMJSD>
       </TabPohybyZbozi>
      </xsl:for-each>
     </PohyboveDoklady>
    </xsl:for-each>
    <Reference>
     <TabDPH>
      <Polozka>
       <Klic>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_dph_0" />
       </Klic>
       <Sazba>0</Sazba>
       <Nazev>Nulová sazba</Nazev>
      </Polozka>
      <Polozka>
       <Klic>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_dph_19" />
       </Klic>
       <Sazba>19</Sazba>
       <Nazev>Stará zákl. sazba EU</Nazev>
      </Polozka>
      <Polozka>
       <Klic>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_dph_20" />
       </Klic>
       <Sazba>20</Sazba>
       <Nazev>Nová zákl. sazba EU</Nazev>
      </Polozka>
     </TabDPH>
     <TabFormaUhrady>
      <Polozka>
       <Klic>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_payment_type" />
       </Klic>
       <FormaUhrady>Zálohou</FormaUhrady>
      </Polozka>
     </TabFormaUhrady>
     <TabStrom>
      <Polozka>
       <Klic>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_stred" />
       </Klic>
       <Cislo>001</Cislo>
       <Nazev>Středisko 001</Nazev>
       <DruhSkladu>1</DruhSkladu>
      </Polozka>
     </TabStrom>
     <TabBankSpojeni>
      <Polozka>
       <Klic>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_bank_spoj" />
       </Klic>
       <NazevBankSpoj>Nazev</NazevBankSpoj>
       <CisloUctu>123</CisloUctu>
       <Prednastaveno>1</Prednastaveno>
       <IDOrg>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_cznic" />
       </IDOrg>
       <Mena>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_cz_currency" />
       </Mena>
       <UcetniUcet>221000</UcetniUcet>
       <Popis>Ucet 221000</Popis>
       <IDUstavu>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_bank" />
       </IDUstavu>
       <CilovaZeme>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_zeme" />
       </CilovaZeme>
      </Polozka>
     </TabBankSpojeni>
     <TabSkupinyZbozi>
      <Polozka>
       <Klic>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_skup" />
       </Klic>
       <SkupZbo>900</SkupZbo>
       <Nazev>Služby</Nazev>
      </Polozka>
     </TabSkupinyZbozi>
     <TabKodMen>
      <Polozka>
       <Klic>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_cz_currency" />
       </Klic>
       <Kod>CZK</Kod>
       <Nazev>Česká koruna</Nazev>
       <MinNasobek>0</MinNasobek>
       <ZaokrouhleniFaktury>0</ZaokrouhleniFaktury>
      </Polozka>
     </TabKodMen>
     <TabMJ>
      <Polozka>
       <Klic>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_maj" />
       </Klic>
       <Kod>ks</Kod>
       <Nazev>kusy</Nazev>
      </Polozka>
     </TabMJ>
     <TabUKod>
      <xsl:if
       test="count(invoice[substring(payment/invoice_number,0,4)='230'])">
       <Polozka>
        <Klic>FK_UKOD_230</Klic>
        <CisloKontace>19</CisloKontace>
       </Polozka>
      </xsl:if>
      <xsl:if
       test="count(invoice[substring(payment/invoice_number,0,4)='240'])">
       <Polozka>
        <Klic>FK_UKOD_240</Klic>
        <CisloKontace>20</CisloKontace>
       </Polozka>
      </xsl:if>
      <xsl:if
       test="count(invoice[substring(payment/invoice_number,0,4)='120'])">
       <Polozka>
        <Klic>FK_UKOD_120</Klic>
        <CisloKontace>26</CisloKontace>
       </Polozka>
      </xsl:if>
      <xsl:if
       test="count(invoice[substring(payment/invoice_number,0,4)='110'])">
       <Polozka>
        <Klic>FK_UKOD_110</Klic>
        <CisloKontace>27</CisloKontace>
       </Polozka>
      </xsl:if>
      <xsl:if
       test="count(invoice[substring(payment/invoice_number,0,4)='231'])">
       <Polozka>
        <Klic>FK_UKOD_231</Klic>
        <CisloKontace>43</CisloKontace>
       </Polozka>
      </xsl:if>
      <xsl:if
       test="count(invoice[substring(payment/invoice_number,0,4)='241'])">
       <Polozka>
        <Klic>FK_UKOD_241</Klic>
        <CisloKontace>42</CisloKontace>
       </Polozka>
      </xsl:if>
      <xsl:if
       test="count(invoice[substring(payment/invoice_number,0,4)='121'])">
       <Polozka>
        <Klic>FK_UKOD_121</Klic>
        <CisloKontace>40</CisloKontace>
       </Polozka>
      </xsl:if>
      <xsl:if
       test="count(invoice[substring(payment/invoice_number,0,4)='111'])">
       <Polozka>
        <Klic>FK_UKOD_111</Klic>
        <CisloKontace>41</CisloKontace>
       </Polozka>
      </xsl:if>
     </TabUKod>
     <TabPenezniUstavy>
      <Polozka>
       <Klic>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_bank" />
       </Klic>
       <KodUstavu>0100</KodUstavu>
       <AlfaKodUstavu>KOMB</AlfaKodUstavu>
       <NazevUstavu>
        <xsl:text>Komerční banka, a.s.</xsl:text>
       </NazevUstavu>
       <SWIFTUstavu>KOMBCZPP</SWIFTUstavu>
      </Polozka>
     </TabPenezniUstavy>
     <xsl:if test="count(invoice/payment[period_from])">
      <TabObdobiStavu>
       <xsl:for-each select="invoice/payment[period_from]">
        <Polozka>
         <Klic>
          <xsl:text>FK_PER_</xsl:text>
          <xsl:value-of select="$pk_period + position()" />
         </Klic>
         <DatumOd>
          <xsl:choose>
           <xsl:when test="count(period_from)">
            <xsl:value-of select="period_from" />
            <xsl:text> 00:00:00.000</xsl:text>
           </xsl:when>
           <xsl:otherwise>
            <xsl:value-of select="advance_payment_date" />
            <xsl:text> 00:00:00.000</xsl:text>
           </xsl:otherwise>
          </xsl:choose>
         </DatumOd>
         <DatumDo>
          <xsl:choose>
           <xsl:when test="count(period_to)">
            <xsl:value-of select="period_to" />
            <xsl:text> 23:59:59.997</xsl:text>
           </xsl:when>
           <xsl:otherwise>
            <xsl:value-of select="advance_payment_date" />
            <xsl:text> 23:59:59.997</xsl:text>
           </xsl:otherwise>
          </xsl:choose>
         </DatumDo>
         <Nazev>Obdobi</Nazev>
        </Polozka>
       </xsl:for-each>
      </TabObdobiStavu>
     </xsl:if>
     <TabZeme>
      <Polozka>
       <Klic>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_zeme" />
       </Klic>
       <ISOKod>CZ</ISOKod>
       <Nazev>Česká republika</Nazev>
       <CelniKod>CZ</CelniKod>
       <EU>1</EU>
      </Polozka>
     </TabZeme>
     <TabCisOrg>
      <xsl:for-each
       select="invoice[
			          count(. | key('invoices-by-client',client/id)[1]) = 1
               ]">
       <Polozka>
        <Klic>
         <xsl:text>FK_CL_</xsl:text>
         <xsl:value-of select="client/id" />
        </Klic>
        <CisloOrg>
         <xsl:value-of select="client/id + 10000" />
        </CisloOrg>
        <Nazev>
         <xsl:value-of select="client/name" />
        </Nazev>
        <PSC>
         <xsl:value-of select="client/address/zip" />
        </PSC>
        <Ulice>
         <xsl:value-of select="client/address/street" />
        </Ulice>
        <Misto>
         <xsl:value-of select="client/address/city" />
        </Misto>
        <ICO>
         <xsl:value-of select="client/ico" />
        </ICO>
        <DIC>
         <xsl:text>FK_DIC_</xsl:text>
         <xsl:value-of select="client/id" />
        </DIC>
        <SlevaSozNa>2</SlevaSozNa>
        <SlevaSkupZbo>2</SlevaSkupZbo>
        <SlevaKmenZbo>2</SlevaKmenZbo>
        <SlevaStavSkladu>2</SlevaStavSkladu>
        <SlevaZbozi>2</SlevaZbozi>
        <SlevaOrg>2</SlevaOrg>
       </Polozka>
      </xsl:for-each>
      <Polozka>
       <Klic>
        <xsl:text>FK_</xsl:text>
        <xsl:value-of select="$pk_cznic" />
       </Klic>
      </Polozka>
     </TabCisOrg>
     <TabDICOrg>
      <xsl:for-each
       select="invoice[
				         count(. | key('invoices-by-client',client/id)[1]) = 1
               ]">
       <Polozka>
        <Klic>
         <xsl:text>FK_DIC_</xsl:text>
         <xsl:value-of select="client/id" />
        </Klic>
        <DIC>
         <!-- in case of VAT starts with a number, 
	      prepend VAT (VGD requirement) before this number -->
         <xsl:if 
          test="contains('0123456789',substring(client/vat_number,0,2))">
          <xsl:text>VAT</xsl:text>
         </xsl:if>
         <xsl:value-of select="client/vat_number" />
        </DIC>
        <CisloOrg>
         <xsl:text>FK_CL_</xsl:text>
         <xsl:value-of select="client/id" />
        </CisloOrg>
        <ISOZeme>
         <xsl:text>FK_</xsl:text>
         <xsl:value-of select="$pk_zeme" />
        </ISOZeme>
       </Polozka>
      </xsl:for-each>
     </TabDICOrg>
     <TabDruhDokZbo>
      <xsl:for-each
       select="invoice[
                count(. | 
                 key('invoices-by-group',substring(payment/invoice_number,0,4)
              	)[1]) = 1]">
       <Polozka>
        <Klic>
         <xsl:text>FK_DDZ_</xsl:text>
         <xsl:call-template name="invoice_group" />
        </Klic>
        <DruhPohybuZbo>13</DruhPohybuZbo>
        <RadaDokladu>
         <xsl:call-template name="invoice_group" />
        </RadaDokladu>
        <Nazev>
         <xsl:text>Rada faktur </xsl:text>
         <xsl:call-template name="invoice_group" />
        </Nazev>
        <PohybSkladu>1</PohybSkladu>
        <DefOKReal>1</DefOKReal>
        <DefOKUcto>1</DefOKUcto>
        <UKod>
         <xsl:text>FK_UKOD_</xsl:text>
         <xsl:call-template name="invoice_group" />
        </UKod>
        <FormaUhrady>
         <xsl:text>FK_</xsl:text>
         <xsl:value-of select="$pk_payment_type" />
        </FormaUhrady>
        <UctoCislovani>1</UctoCislovani>
        <VyrZaplZaloh>1</VyrZaplZaloh>
       </Polozka>
      </xsl:for-each>
     </TabDruhDokZbo>
     <xsl:if
      test="count(invoice/advance_payment/applied_invoices/consumed)">
      <TabZalFak>
       <xsl:for-each
        select="invoice[advance_payment/applied_invoices/consumed]">
        <Polozka>
         <Klic>
          <xsl:text>FK_ZALFAK_</xsl:text>
          <xsl:value-of select='payment/invoice_number' />
         </Klic>
         <xsl:for-each select='advance_payment/applied_invoices/consumed'>
          <ZalohovaFaktura>
           <IDZal>
            <xsl:text>FK_DZ_</xsl:text>
            <xsl:value-of select="number" />
           </IDZal>
           <CsDPH1>
            <xsl:value-of select="pricevat" />
           </CsDPH1>
           <CbezDPH1>
            <xsl:value-of select="price" />
           </CbezDPH1>
           <CastkaDPH1>
            <xsl:value-of select="vat" />
           </CastkaDPH1>
           <CsDPH1Val>
            <xsl:value-of select="pricevat" />
           </CsDPH1Val>
           <CbezDPH1Val>
            <xsl:value-of select="total" />
           </CbezDPH1Val>
           <CastkaDPH1Val>
            <xsl:value-of select="totalvat" />
           </CastkaDPH1Val>
           <SazbaDPH1>
            <xsl:call-template name="pk_sazba_dph">
             <xsl:with-param name="sazba"
              select="../../../
                      delivery/vat_rates/entry[position()=1]/vatperc" />
            </xsl:call-template>
           </SazbaDPH1>
           <Popis>
            <xsl:call-template name='invoice_number'>
             <xsl:with-param name='number' select="number" />
            </xsl:call-template>
           </Popis>
           <Datum>
            <xsl:value-of select="crtime" />
           </Datum>
          </ZalohovaFaktura>
         </xsl:for-each>
        </Polozka>
       </xsl:for-each>
      </TabZalFak>
      <TabDokladyZbozi>
       <xsl:for-each
        select="invoice/advance_payment/applied_invoices/consumed[
                 count(. | key('adv-inv-by-number',number)[1]) = 1
                ]">
        <Polozka>
         <xsl:variable name='num'>
          <xsl:call-template name='invoice_number'>
           <xsl:with-param name='number' select="number" />
          </xsl:call-template>
         </xsl:variable>
         <Klic>
          <xsl:text>FK_DZ_</xsl:text>
          <xsl:value-of select="number" />
         </Klic>
         <DruhPohybuZbo>13</DruhPohybuZbo>
         <PoradoveCislo>
          <xsl:value-of select="substring($num, 4)" />
         </PoradoveCislo>
         <RadaDokladu>
          <xsl:value-of select="substring($num, 0, 4)" />
         </RadaDokladu>
         <DatPorizeni>
          <xsl:value-of select="../../../payment/tax_point" />
         </DatPorizeni>
        </Polozka>
       </xsl:for-each>
      </TabDokladyZbozi>
      <TabStavSkladu>
       <xsl:for-each
        select="invoice/delivery/vat_rates/entry/years/entry[
                 count(. | key('entries-by-year',year)[1]) = 1
                ]">
        <Polozka>
         <Klic>
          <xsl:text>FK_SS_</xsl:text>
          <xsl:value-of select='year' />
         </Klic>
         <JizNaSklade>1</JizNaSklade>
         <IDKmenZbozi>
          <xsl:text>FK_KZ_</xsl:text>
          <xsl:value-of select='year' />
         </IDKmenZbozi>
         <IDSklad>
          <xsl:text>FK_</xsl:text>
          <xsl:value-of select='$pk_stred' />
         </IDSklad>
        </Polozka>
       </xsl:for-each>
      </TabStavSkladu>
      <TabKmenZbozi>
       <xsl:for-each
        select="invoice/delivery/vat_rates/entry/years/entry[
                 count(. | key('entries-by-year',year)[1]) = 1
                ]">
        <Polozka>
         <Klic>
          <xsl:text>FK_KZ_</xsl:text>
          <xsl:value-of select='year' />
         </Klic>
         <PrepMnozstvi>1</PrepMnozstvi>
         <SazbaDPHVstup>
          <xsl:call-template name="pk_sazba_dph">
           <xsl:with-param name="sazba" select="../../vatperc" />
          </xsl:call-template>
         </SazbaDPHVstup>
         <SazbaDPHVystup>
          <xsl:call-template name="pk_sazba_dph">
           <xsl:with-param name="sazba" select="../../vatperc" />
          </xsl:call-template>
         </SazbaDPHVystup>
         <RegCis>
          <xsl:text>0</xsl:text>
          <xsl:value-of select='year' />
         </RegCis>
         <Nazev1>
          <xsl:text>Výnosy roku </xsl:text>
          <xsl:value-of select='year' />
         </Nazev1>
         <DruhSkladu>0</DruhSkladu>
         <SkupZbo>
          <xsl:text>FK_</xsl:text>
          <xsl:value-of select='$pk_skup' />
         </SkupZbo>
         <MJEvidence>
          <xsl:text>FK_</xsl:text>
          <xsl:value-of select="$pk_maj" />
         </MJEvidence>
         <MJVstup>
          <xsl:text>FK_</xsl:text>
          <xsl:value-of select="$pk_maj" />
         </MJVstup>
         <MJVystup>
          <xsl:text>FK_</xsl:text>
          <xsl:value-of select="$pk_maj" />
         </MJVystup>
         <ZakladSDvSJ>0</ZakladSDvSJ>
        </Polozka>
       </xsl:for-each>
      </TabKmenZbozi>
     </xsl:if>
    </Reference>
   </body>
  </HeliosIQ_1>
 </xsl:template>

</xsl:stylesheet>
