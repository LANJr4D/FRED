---
--- don't forget to update database schema version
---
UPDATE enum_parameters SET val = '2.8.1' WHERE id = 1;


UPDATE mail_templates SET template = '
This is a bilingual message. Please see below for the English version

Vážená paní, vážený pane,

dovolujeme si Vás zdvořile požádat o kontrolu správnosti údajů,
které nyní evidujeme u Vašeho kontaktu v centrálním registru
doménových jmen.

ID kontaktu v registru: <?cs var:handle ?>
Organizace: <?cs var:organization ?>
Jméno: <?cs var:name ?>
Adresa: <?cs var:address ?><?cs if:ident_type != "" ?>
<?cs if:ident_type == "RC"?>Datum narození: <?cs 
elif:ident_type == "OP"?>Číslo OP: <?cs 
elif:ident_type == "PASS"?>Číslo pasu: <?cs 
elif:ident_type == "ICO"?>IČO: <?cs 
elif:ident_type == "MPSV"?>Identifikátor MPSV: <?cs 
elif:ident_type == "BIRTHDAY"?>Datum narození: <?cs 
/if ?> <?cs var:ident_value ?><?cs 
/if ?>
DIČ: <?cs var:dic ?>
Telefon: <?cs var:telephone ?>
Fax: <?cs var:fax ?>
E-mail: <?cs var:email ?>
Notifikační e-mail: <?cs var:notify_email ?>
Určený registrátor: <?cs var:registrar_name ?> (<?cs var:registrar_url ?>)
<?cs if:registrar_memo_cz ?>Další informace poskytnuté registrátorem:
<?cs var:registrar_memo_cz ?><?cs /if ?>

Se žádostí o opravu údajů se neváhejte obrátit na svého vybraného registrátora.
V případě, že zde uvedené údaje odpovídají skutečnosti, není nutné na tuto zprávu reagovat.

Aktuální, úplné a správné informace v registru znamenají Vaši jistotu,
že Vás důležité informace o Vaší doméně zastihnou vždy a včas na správné adrese.
Nedočkáte se tak nepříjemného překvapení v podobě nefunkční či zrušené domény.

Dovolujeme si Vás rovněž upozornit, že nesprávné, nepravdivé, neúplné
či zavádějící údaje mohou být v souladu s Pravidly registrace doménových jmen
v ccTLD .cz důvodem ke zrušení registrace doménového jména!

Chcete mít snadnější přístup ke správě Vašich údajů? Založte si mojeID na www.mojeid.cz.
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
<?cs var:item ?><?cs /each ?><?cs else ?>Kontakt není uveden u žádného doménového jména.<?cs /if ?><?cs if:nssets.0 ?>

Seznam sad jmenných serverů, kde je kontakt v roli technického kontaktu:<?cs each:item = nssets ?>
<?cs var:item ?><?cs /each ?><?cs /if ?><?cs if:keysets.0 ?>

Seznam sad klíčů, kde je kontakt v roli technického kontaktu:<?cs each:item = keysets ?>
<?cs var:item ?><?cs /each ?><?cs /if ?>



Dear Sir or Madam,

Please check the correctness of the information we currently have on file
for your contact in the central registry of domain names.

Contact ID in the registry: <?cs var:handle ?>
Organization: <?cs var:organization ?>
Name: <?cs var:name ?>
Address: <?cs var:address ?><?cs if:ident_type != "" ?>
<?cs if:ident_type == "RC"?>Birth date: <?cs 
elif:ident_type == "OP"?>Personal ID: <?cs 
elif:ident_type == "PASS"?>Passport number: <?cs 
elif:ident_type == "ICO"?>ID number: <?cs 
elif:ident_type == "MPSV"?>MSPV ID: <?cs 
elif:ident_type == "BIRTHDAY"?>Birth day: <?cs 
/if ?> <?cs var:ident_value ?><?cs 
/if ?>
VAT No.: <?cs var:dic ?>
Phone: <?cs var:telephone ?>
Fax: <?cs var:fax ?>
E-mail: <?cs var:email ?>
Notification e-mail: <?cs var:notify_email ?>
Designated registrator: <?cs var:registrar_name ?> (<?cs var:registrar_url ?>)
<?cs if:registrar_memo_en ?>Other information provided by registrar:
<?cs var:registrar_memo_en ?><?cs /if ?>

Do not hesitate to contact your designated registrar with a correction request.

Having up-to-date, complete and correct information in the registry is crucial
to reach you with all the important information about your domain name in a timely manner
and at the correct contact address. Check you contact details now and avoid unpleasant
surprises such as a non-functional or expired domain.

We would also like to inform you that in accordance with the Rules of Domain Name
Registration for the .cz ccTLD, incorrect, false, incomplete or misleading
information can be grounds for the cancellation of a domain name registration.

Please do not hesitate to contact us for additional information.

You can find a complete summary of your domain names, and other objects
associated with your contact attached below.


Your CZ.NIC team.

Attachment:

<?cs if:domains.0 ?>Domains where the contact is a holder or an administrative or a temporary contact:<?cs each:item = domains ?>
<?cs var:item ?><?cs /each ?><?cs else ?>Contact is not linked to any domain name.<?cs /if ?><?cs if:nssets.0 ?>

Sets of name servers where the contact is a technical contact:<?cs each:item = nssets ?>
<?cs var:item ?><?cs /each ?><?cs /if ?><?cs if:keysets.0 ?>

Keysets where the contact is a technical contact:<?cs each:item = keysets ?>
<?cs var:item ?><?cs /each ?><?cs /if ?>
' WHERE id = 23;


UPDATE
    enum_object_states
    SET external = true
  WHERE name = 'deleteCandidate';

UPDATE
    enum_object_states_desc
    SET description = 'Určeno ke zrušení'
  WHERE lang = 'CS'
        AND state_id = (SELECT id FROM enum_object_states WHERE name = 'deleteCandidate');

UPDATE
    enum_object_states_desc
    SET description = 'To be deleted'
  WHERE lang = 'EN'
        AND state_id = (SELECT id FROM enum_object_states WHERE name = 'deleteCandidate');


---
--- Ticket #5917
---
INSERT INTO enum_parameters (id, name, val)
    VALUES (14, 'regular_day_outzone_procedure_period', '14');

UPDATE enum_parameters
    SET val = '0' WHERE name = 'regular_day_procedure_period';

