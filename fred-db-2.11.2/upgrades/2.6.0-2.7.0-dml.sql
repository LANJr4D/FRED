---
--- Ticket #5102 - reminder - mail template
---

INSERT INTO mail_type (id, name, subject) VALUES (23, 'annual_contact_reminder', 'Ověření správnosti údajů');
INSERT INTO mail_templates (id, contenttype, footer, template) VALUES
 (23, 'plain', 1,
'
English version of the e-mail is entered below the Czech version

Vážená paní, vážený pane,

dovolujeme si Vás zdvořile požádat o kontrolu správnosti údajů,
které nyní evidujeme u Vašeho kontaktu v centrálním registru
doménových jmen.

ID kontaktu v registru: <?cs var:handle ?>
Organizace: <?cs var:organization ?>
Jméno: <?cs var:name ?>
Adresa: <?cs var:address ?><?cs if:ident_type != "" ?>
<?cs var:ident_type ?>: <?cs var:ident_value ?><?cs /if ?>
DIČ: <?cs var:dic ?>
Telefon: <?cs var:telephone ?>
Fax: <?cs var:fax ?>
E-mail: <?cs var:email ?>
Notifikační e-mail: <?cs var:notify_email ?>
Určený registrátor: <?cs var:registrar_name ?> (<?cs var:registrar_url ?>)
<?cs if:registrar_memo ?>Další informace poskytnuté registrátorem:
<?cs var:registrar_memo ?><?cs /if ?>

Se žádostí o opravu údajů se neváhejte obrátit na svého vybraného registrátora.

Aktuální, úplné a správné informace v registru znamenají Vaši jistotu,
že Vás důležité informace o Vaší doméně zastihnou vždy a včas na správné adrese.
Nedočkáte se tak nepříjemného překvapení v podobě nefunkční či zrušené domény.
Dovolujeme si Vás rovněž upozornit, že nesprávné, nepravdivé, neúplné
či zavádějící údaje mohou být v souladu s Pravidly registrace doménových jmen
v ccTLD .cz důvodem ke zrušení registrace doménového jména!

Chcete mít snadnější přístup ke správě Vašich údajů? Založte si mojeID.
Kromě nástroje, kterým můžete snadno a bezpečně spravovat údaje v centrálním
registru, získáte také prostředek pro jednoduché přihlašování k Vašim oblíbeným
webovým službám jediným jménem a heslem.

Pro více informací nás neváhejte kontaktovat!

Úplný výpis z registru obsahující všechny domény a další objekty přiřazené
k shora uvedenému kontaktu naleznete v příloze.

Váš tým CZ.NIC.

Příloha:

<?cs if:domains.0 ?>Seznam domén kde je kontakt v roli držitele nebo administrativního
nebo dočasného kontaktu:<?cs each:item = domains ?>
<?cs var:item ?><?cs /each ?><?cs else ?>Kontakt není uveden u žádného doménového jména.<?cs /if ?>

<?cs if:nssets.0 ?>Seznam sad jmenných serverů, kde je kontakt v roli technického kontaktu:<?cs each:item = nssets ?>
<?cs var:item ?><?cs /each ?><?cs else ?>Kontakt není uveden u žádné sady jmenných serverů.<?cs /if ?>

<?cs if:keysets.0 ?>Seznam sad klíčů, kde je kontakt v roli technického kontaktu:<?cs each:item = keysets ?>
<?cs var:item ?><?cs /each ?><?cs else ?>Kontakt není uveden u žádné sady klíčů.<?cs /if ?>



Dear Sir or Madam,

Please check the accuracy of the information we currently have on file
for your contact in the central registry of domain names.

Contact ID in the registry: <?cs var:handle ?>
Organization: <?cs var:organization ?>
Name: <?cs var:name ?>
Address: <?cs var:address ?><?cs if:ident_type != "" ?>
<?cs var:ident_type ?>: <?cs var:ident_value ?><?cs /if ?>
VAT No.: <?cs var:dic ?>
Phone: <?cs var:telephone ?>
Fax: <?cs var:fax ?>
E-mail: <?cs var:email ?>
Notification e-mail: <?cs var:notify_email ?>
Designated registrator: <?cs var:registrar_name ?> (<?cs var:registrar_url ?>)
<?cs if:registrar_memo ?>Other information provided by registrar:
<?cs var:registrar_memo ?><?cs /if ?>

Do not hesitate to contact your selected registrar with a correction request.

Having current, complete and accurate information in the registry means
you can be sure the important information about your domain is always available
in time at the right address. In this way you will avoid an unpleasant surprise
in the form of a non-functioning or cancelled domain.

We would also like to inform you that in accordance with the Rules of Domain Name
Registration for the .cz ccTLD, incorrect, false, incomplete or misleading
information can be grounds for the cancellation of a domain name registration.

Please do not hesitate to contact us for additional information.

You can find attached a complete extract from the registry containing
all the domains and other items associated with the above contact.

Your CZ.NIC team.

Attachment:

<?cs if:domains.0 ?>List of domains where the contact is a holder or an administrative
or temporary contact:<?cs each:item = domains ?>
<?cs var:item ?><?cs /each ?><?cs else ?>Contact is not linked to any domain name.<?cs /if ?>

<?cs if:nssets.0 ?>List of sets of name servers on which the contact is a technical contact:<?cs each:item = nssets ?>
<?cs var:item ?><?cs /each ?><?cs else ?>Contact is not linked to any name server.<?cs /if ?>

<?cs if:keysets.0 ?>List of keysets on which the contact is a technical contact:<?cs each:item = keysets ?>
<?cs var:item ?><?cs /each ?><?cs else ?>Contact is not linked to any keyset.<?cs /if ?>
');
INSERT INTO mail_type_template_map (typeid, templateid) VALUES (23, 23);


---
--- Ticket #4910 - email/phone change with pin 
---

INSERT INTO mail_type (id, name, subject) VALUES (24, 'mojeid_email_change', 'MojeID - změna emailu');
INSERT INTO mail_templates (id, contenttype, footer, template) VALUES
(24, 'plain', 1,
'Vážený uživateli,

k dokončení procedury změny emailu zadejte prosím kód PIN1: <?cs var:pin ?>

Váš tým CZ.NIC');
INSERT INTO mail_type_template_map (typeid, templateid) VALUES (24, 24);

INSERT INTO message_type (id, type) VALUES (4, 'mojeid_sms_change');

