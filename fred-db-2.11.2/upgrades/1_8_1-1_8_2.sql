UPDATE enum_parameters SET val='1.8.2' WHERE id=1;

CREATE INDEX epp_info_buffer_content_registrar_id_idx ON epp_info_buffer_content (registrar_id);
CREATE INDEX mail_archive_status_idx ON mail_archive (status);
CREATE INDEX mail_attachments_mailid_idx ON mail_attachments (mailid);

CREATE INDEX poll_statechange_stateid_idx ON poll_statechange (stateid);

DROP TABLE enum_status;

UPDATE mail_templates SET template=
'
=====================================================================
Oznámení o zrušení / Delete notification 
=====================================================================
Vzhledem ke skutečnosti, že <?cs if:type == #1 ?>kontaktní osoba<?cs elif:type == #2 ?>sada nameserverů<?cs /if ?> <?cs var:handle ?>
<?cs var:name ?> nebyla po stanovenou dobu používána, <?cs var:defaults.company ?>
na základě Pravidel registrace ruší ke dni <?cs var:deldate ?> uvedenou
<?cs if:type == #1 ?>kontaktní osobu<?cs elif:type == #2 ?>sadu nameserverů<?cs /if ?>.

Zrušení <?cs if:type == #1 ?>kontaktní osoby<?cs elif:type == #2 ?>sady nameserverů<?cs /if ?> nemá žádný vliv na funkčnost Vašich 
zaregistrovaných doménových jmen.

With regard to the fact that the <?cs if:type == #1 ?>contact<?cs elif:type == #2 ?>NS set<?cs /if ?> <?cs var:handle ?>
<?cs var:name ?> was not used during the fixed period, <?cs var:defaults.company ?>
is cancelling the aforementioned <?cs if:type == #1 ?>contact<?cs elif:type == #2 ?>set of nameservers<?cs /if ?> as of <?cs var:deldate ?>.

Cancellation of <?cs if:type == #1 ?>contact<?cs elif:type == #2 ?>NS set<?cs /if ?> has no influence on functionality of your
registred domains.
=====================================================================


                                             S pozdravem
                                             podpora <?cs var:defaults.company ?>
' WHERE id=14;
