---
--- **********************************************************
--- *                                                        *
--- * new stuff                                              *
--- *                                                        *
--- **********************************************************
---

---
---  new DNSSEC related tables
---

CREATE TABLE Keyset (
    id integer PRIMARY KEY REFERENCES object (id)
);

comment on table Keyset is 'Evidence of Keysets';
comment on column Keyset.id is 'reference into object table';


CREATE TABLE keyset_contact_map (
    keysetid integer REFERENCES Keyset(id) ON UPDATE CASCADE NOT NULL,
    contactid integer REFERENCES Contact(ID) ON UPDATE CASCADE ON DELETE CASCADE NOT NULL,
    PRIMARY KEY (contactid, keysetid)
);
CREATE INDEX keyset_contact_map_contact_idx ON keyset_contact_map (contactid);
CREATE INDEX keyset_contact_map_keyset_idx ON keyset_contact_map (keysetid);

CREATE TABLE DSRecord (
    id serial PRIMARY KEY,
    keysetid integer REFERENCES Keyset(id) ON UPDATE CASCADE NOT NULL,
    keyTag integer NOT NULL,
    alg integer NOT NULL,
    digestType integer NOT NULL,
    digest varchar(255) NOT NULL,
    maxSigLife integer
);

comment on table DSRecord is 'table with DS resource records'; 
comment on column DSRecord.id is 'unique automatically generated identifier';
comment on column DSRecord.keysetid is 'reference to relevant record in Keyset table';
comment on column DSRecord.keyTag is '';
comment on column DSRecord.alg is 'used algorithm. See RFC 4034 appendix A.1 for list';
comment on column DSRecord.digestType is 'used digest type. See RFC 4034 appendix A.2 for list';
comment on column DSRecord.digest is 'digest of DNSKEY';
comment on column DSRecord.maxSigLife is 'record TTL';

---
--- new DNSSEC related history tables
---

CREATE TABLE Keyset_history (
    historyid integer PRIMARY KEY REFERENCES History,
    id integer REFERENCES object_registry(id)
);

comment on table Keyset_history is 'historic data from Keyset table';

CREATE TABLE keyset_contact_map_history (
    historyid integer REFERENCES History,
    keysetid integer REFERENCES object_registry(id),
    contactid integer REFERENCES object_registry(id),
    PRIMARY KEY (historyid, contactid, keysetid)
);

CREATE TABLE DSRecord_history (
    historyid integer REFERENCES History,
    id integer NOT NULL,
    keysetid integer NOT NULL,
    keyTag integer NOT NULL,
    alg integer NOT NULL,
    digestType integer NOT NULL,
    digest varchar(255) NOT NULL,
    maxSigLife integer,
    PRIMARY KEY (historyid, id)
);

comment on table DSRecord_history is 'historic data from DSRecord table';


---
--- changes in existing tables
---

ALTER TABLE Domain ADD COLUMN keyset integer REFERENCES Keyset(id);

comment on column Domain.keyset is 'reference to used keyset';

ALTER TABLE Domain_History ADD COLUMN keyset integer;

---
--- new records in existing tables
---

INSERT INTO enum_action VALUES (600, 'KeysetCheck');
INSERT INTO enum_action VALUES (601, 'KeysetInfo');
INSERT INTO enum_action VALUES (602, 'KeysetDelete');
INSERT INTO enum_action VALUES (603, 'KeysetUpdate');
INSERT INTO enum_action VALUES (604, 'KeysetCreate');
INSERT INTO enum_action VALUES (605, 'KeysetTransfer');
INSERT INTO enum_action VALUES (1006, 'ListKeySet');
INSERT INTO enum_action VALUES (1106, 'KeySetSendAuthInfo');

---
--- error reason values
---

INSERT INTO enum_reason VALUES (39, 'Bad format keyset handle', 'Neplatný formát ukazatele keysetu');
INSERT INTO enum_reason VALUES (40, 'Handle of keyset does not exists', 'Ukazatel keysetu není vytvořen');
INSERT INTO enum_reason VALUES (41, 'DSRecord does not exists', 'DSRecord záznam neexistuje');
INSERT INTO enum_reason VALUES (42, 'Can not remove DSRecord', 'Nelze odstranit DSRecord záznam');
INSERT INTO enum_reason VALUES (43, 'Duplicity DSRecord', 'Duplicitní DSRecord záznam');
INSERT INTO enum_reason VALUES (44, 'DSRecord already exists for this keyset', 'DSRecord již pro tento keyset existuje');
INSERT INTO enum_reason VALUES (45, 'DSRedord is not set for this keyset', 'DSRecord pro tento keyset neexistuje');
INSERT INTO enum_reason VALUES (46, 'Field ``digest type'''' must be 1 (SHA-1)', 'Pole ``digest type'''' musí být 1 (SHA-1)');
INSERT INTO enum_reason VALUES (47, 'Digest must be 40 character long', 'Digest musí být dlouhý 40 znaků');

select setval('enum_reason_id_seq', 47);

---
--- Values to table messagetype (see poll.sql)
---

INSERT INTO MessageType VALUES (14, 'transfer_keyset');
INSERT INTO MessageType VALUES (15, 'delete_keyset');


---
--- **********************************************************
--- *                                                        *
--- * updates to existing stuff                              *
--- *                                                        *
--- **********************************************************
---

--
-- create object and return it's id. duplicate is not raised as exception
-- but return 0 as id instead. it expect unique index on table
-- object_registry. cannot check enum subdomains!!!
--
CREATE OR REPLACE FUNCTION create_object(
 crregid INTEGER, 
 oname VARCHAR, 
 otype INTEGER
) 
RETURNS INTEGER AS $$
DECLARE iid INTEGER;
BEGIN
 iid := NEXTVAL('object_registry_id_seq');
 INSERT INTO object_registry (id,roid,name,type,crid) 
 VALUES (
  iid,
  (ARRAY['C','N','D', 'K'])[otype] || LPAD(iid::text,10,'0') || '-CZ' ,
  CASE
   WHEN otype=1 THEN UPPER(oname)
   WHEN otype=2 THEN UPPER(oname)
   WHEN otype=3 THEN LOWER(oname)
   WHEN otype=4 THEN UPPER(oname)
  END,
  otype,
  crregid
 );
 RETURN iid;
 EXCEPTION
 WHEN UNIQUE_VIOLATION THEN RETURN 0;
END;
$$ LANGUAGE plpgsql;

-- when technical/administrative contact not exist or is already assigned to object (domain/keyset/nsset)
update enum_reason set reason='Technical contact is already assigned to this object.', reason_cs='Technický kontakt je již přiřazen k tomuto objektu' where id=24;
update enum_reason set reason='Technical contact not exists', reason_cs='Technický kontakt neexistuje' where id=25;
update enum_reason set reason='Administrative contact is already assigned to this object.', reason_cs='Administrátorký kontakt je již přiřazen k tomuto objektu' where id=26;
update enum_reason set reason='Administravite contact not exists', reason_cs='Administrátorký kontakt neexistuje' where id=27;


UPDATE mail_templates SET template =
'English version of the e-mail is entered below the Czech version

Zaslání autorizační informace

Vážený zákazníku,

   na základě Vaší žádosti podané prostřednictvím webového formuláře
na stránkách sdružení dne <?cs var:reqdate ?>, které
bylo přiděleno identifikační číslo <?cs var:reqid ?>, Vám zasíláme požadované
heslo, příslušející <?cs if:type == #3 ?>k doméně<?cs elif:type == #1 ?>ke kontaktu s identifikátorem<?cs elif:type == #2 ?>k sadě nameserverů s identifikátorem<?cs elif:type == #4 ?>k sadě klíčů s identifikátorem<?cs /if ?> <?cs var:handle ?>.

   Heslo je: <?cs var:authinfo ?>

   V případě, že jste tuto žádost nepodali, oznamte prosím tuto
skutečnost na adresu <?cs var:defaults.emailsupport ?>.

                                             S pozdravem
                                             podpora <?cs var:defaults.company ?>



Sending authorization information

Dear customer,

   Based on your request submitted via the web form on the association
pages on <?cs var:reqdate ?>, which received
the identification number <?cs var:reqid ?>, we are sending you the requested
password that belongs to the <?cs if:type == #3 ?>domain name<?cs elif:type == #1 ?>contact with identifier<?cs elif:type == #2 ?>NS set with identifier<?cs elif:type == #4 ?>Keyset with identifier<?cs /if ?> <?cs var:handle ?>.

   The password is: <?cs var:authinfo ?>

   If you did not submit the aforementioned request, please, notify us about
this fact at the following address <?cs var:defaults.emailsupport ?>.


                                             Yours sincerely
                                             support <?cs var:defaults.company ?>
' WHERE id=1;

UPDATE mail_templates SET template = 
'English version of the e-mail is entered below the Czech version

Zaslání autorizační informace

Vážený zákazníku,

   na základě Vaší žádosti podané prostřednictvím registrátora
<?cs var:registrar ?>, jejímž obsahem je žádost o zaslání hesla
příslušející <?cs if:type == #3 ?>k doméně<?cs elif:type == #1 ?>ke kontaktu s identifikátorem<?cs elif:type == #2 ?>k sadě nameserverů s identifikátorem<?cs elif:type == #4 ?>k sadě klíčů s identifikátorem<?cs /if ?> <?cs var:handle ?>.

   Heslo je: <?cs var:authinfo ?>

   Tato zpráva je zaslána pouze na e-mailovou adresu uvedenou u příslušné
osoby v Centrálním registru doménových jmen.

   V případě, že jste tuto žádost nepodali, oznamte prosím tuto
skutečnost na adresu <?cs var:defaults.emailsupport ?>.


                                             S pozdravem
                                             podpora <?cs var:defaults.company ?>



Sending authorization information

Dear customer,

   Based on your request submitted via the registrar <?cs var:registrar ?>,
which contains your request for sending you the password that belongs to
the <?cs if:type == #3 ?>domain name<?cs elif:type == #1 ?>contact with identifier<?cs elif:type == #2 ?>NS set with identifier<?cs elif:type == #4 ?>Keyset with identifier<?cs /if ?> <?cs var:handle ?>.

   The password is: <?cs var:authinfo ?>

   This message is being sent only to the e-mail address that we have on file
for a particular person in the Central Registry of Domain Names.

   If you did not submit the aforementioned request, please, notify us about
this fact at the following address <?cs var:defaults.emailsupport ?>.


                                             Yours sincerely
                                             support <?cs var:defaults.company ?>
' WHERE id=2;

UPDATE mail_templates SET template =
'<?cs def:typesubst(lang) ?><?cs if:lang == "cs" ?><?cs if:type == #3 ?>domény<?cs elif:type == #1 ?>kontaktu<?cs elif:type == #2 ?>sady nameserverů<?cs elif:type == #4 ?>sady klíčů<?cs /if ?><?cs elif:lang == "en" ?><?cs if:type == #3 ?>Domain<?cs elif:type == #1 ?>Contact<?cs elif:type == #2 ?>NS set<?cs elif:type == #4 ?>Keyset<?cs /if ?><?cs /if ?><?cs /def ?>
======================================================================
Oznámení o registraci / Registration notification
======================================================================
Registrace <?cs call:typesubst("cs") ?> / <?cs call:typesubst("en") ?> create 
Identifikátor <?cs call:typesubst("cs") ?> / <?cs call:typesubst("en") ?> handle : <?cs var:handle ?>
Číslo žádosti / Ticket :  <?cs var:ticket ?>
Registrátor / Registrar : <?cs var:registrar ?>
======================================================================

Žádost byla úspešně zpracována, požadovaná registrace byla provedena. 
The request was completed successfully, required registration was done. 

Detail <?cs call:typesubst("cs") ?> najdete na <?cs var:defaults.whoispage ?>.
For detail information about <?cs call:typesubst("en") ?> visit <?cs var:defaults.whoispage ?>.


                                             S pozdravem
                                             podpora <?cs var:defaults.company ?>
' WHERE id=10;

UPDATE mail_templates SET template =
'<?cs def:typesubst(lang) ?><?cs if:lang == "cs" ?><?cs if:type == #3 ?>domény<?cs elif:type == #1 ?>kontaktu<?cs elif:type == #2 ?>sady nameserverů<?cs elif:type == #4 ?>sady klíčů<?cs /if ?><?cs elif:lang == "en" ?><?cs if:type == #3 ?>Domain<?cs elif:type == #1 ?>Contact<?cs elif:type == #2 ?>NS set<?cs elif:type == #4 ?>Keyset<?cs /if ?><?cs /if ?><?cs /def ?>
=====================================================================
Oznámení změn / Notification of changes 
=====================================================================
Změna údajů <?cs call:typesubst("cs") ?> / <?cs call:typesubst("en") ?> data change 
Identifikátor <?cs call:typesubst("cs") ?> / <?cs call:typesubst("en") ?> handle : <?cs var:handle ?>
Číslo žádosti / Ticket :  <?cs var:ticket ?>
Registrátor / Registrar : <?cs var:registrar ?>
=====================================================================
 
Žádost byla úspešně zpracována, požadované změny byly provedeny. 
The request was completed successfully, required changes were done. 

Detail <?cs call:typesubst("cs") ?> najdete na <?cs var:defaults.whoispage ?>.
For detail information about <?cs call:typesubst("en") ?> visit <?cs var:defaults.whoispage ?>.


                                             S pozdravem
                                             podpora <?cs var:defaults.company ?>
' WHERE id=11;

UPDATE mail_templates SET template = 
'<?cs def:typesubst(lang) ?><?cs if:lang == "cs" ?><?cs if:type == #3 ?>domény<?cs elif:type == #1 ?>kontaktu<?cs elif:type == #2 ?>sady nameserverů<?cs elif:type == #4 ?>sady klíčů<?cs /if ?><?cs elif:lang == "en" ?><?cs if:type == #3 ?>Domain<?cs elif:type == #1 ?>Contact<?cs elif:type == #2 ?>NS set<?cs elif:type == #4 ?>Keyset<?cs /if ?><?cs /if ?><?cs /def ?>
=====================================================================
Oznámení o transferu / Transfer notification
=====================================================================
Transfer <?cs call:typesubst("cs") ?> / <?cs call:typesubst("en") ?> transfer
Identifikátor <?cs call:typesubst("cs") ?> / <?cs call:typesubst("en") ?> handle : <?cs var:handle ?>
Číslo žádosti / Ticket :  <?cs var:ticket ?>
Registrátor / Registrar : <?cs var:registrar ?>
=====================================================================
 
Žádost byla úspešně zpracována, transfer byl proveden. 
The request was completed successfully, transfer was completed. 

Detail <?cs call:typesubst("cs") ?> najdete na <?cs var:defaults.whoispage ?>.
For detail information about <?cs call:typesubst("en") ?> visit <?cs var:defaults.whoispage ?>.


                                             S pozdravem
                                             podpora <?cs var:defaults.company ?>
' WHERE id=12;

UPDATE mail_templates SET template = 
'
=====================================================================
Oznámení o zrušení / Delete notification 
=====================================================================
Vzhledem ke skutečnosti, že <?cs if:type == #1 ?>kontaktní osoba<?cs elif:type == #2 ?>sada nameserverů<?cs elif:type == #4 ?>sada klíčů<?cs /if ?> <?cs var:handle ?>
<?cs var:name ?> nebyla po stanovenou dobu používána, <?cs var:defaults.company ?> ruší ke dni <?cs var:deldate ?> uvedenou
<?cs if:type == #1 ?>kontaktní osobu<?cs elif:type == #2 ?>sadu nameserverů<?cs /if ?>.

Zrušení <?cs if:type == #1 ?>kontaktní osoby<?cs elif:type == #2 ?>sady nameserverů<?cs /if ?> nemá žádný vliv na funkčnost Vašich 
zaregistrovaných doménových jmen.

With regard to the fact that the <?cs if:type == #1 ?>contact<?cs elif:type == #2 ?>NS set<?cs elif:type == #4 ?>Keyset<?cs /if ?> <?cs var:handle ?>
<?cs var:name ?> was not used during the fixed period, <?cs var:defaults.company ?>
is cancelling the aforementioned <?cs if:type == #1 ?>contact<?cs elif:type == #2 ?>set of nameservers<?cs /if ?> as of <?cs var:deldate ?>.

Cancellation of <?cs if:type == #1 ?>contact<?cs elif:type == #2 ?>NS set<?cs /if ?> has no influence on functionality of your
registred domains.
=====================================================================


                                             S pozdravem
                                             podpora <?cs var:defaults.company ?>
' WHERE id=14;

UPDATE mail_templates SET template =
'<?cs def:typesubst(lang) ?><?cs if:lang == "cs" ?><?cs if:type == #3 ?>domény<?cs elif:type == #1 ?>kontaktu<?cs elif:type == #2 ?>sady nameserverů<?cs elif:type == #4 ?>sady klíčů<?cs /if ?><?cs elif:lang == "en" ?><?cs if:type == #3 ?>Domain<?cs elif:type == #1 ?>Contact<?cs elif:type == #2 ?>NS set<?cs elif:type == #4 ?>Keyset<?cs /if ?><?cs /if ?><?cs /def ?>
=====================================================================
Oznámení o zrušení / Delete notification 
=====================================================================
Zrušení <?cs call:typesubst("cs") ?> / <?cs call:typesubst("en") ?> deletion
Identifikator <?cs call:typesubst("cs") ?> / <?cs call:typesubst("en") ?> handle : <?cs var:handle ?>
Cislo zadosti / Ticket :  <?cs var:ticket ?>
Registrator / Registrar : <?cs var:registrar ?>
=====================================================================
 
Žádost byla úspěšně zpracována, požadované zrušení bylo provedeno. 
The request was completed successfully, required delete was done. 
 
=====================================================================


                                             S pozdravem
                                             podpora <?cs var:defaults.company ?>
' WHERE id=15;

UPDATE mail_templates SET template =
'English version of the e-mail is entered below the Czech version

Informace o vyřízení žádosti

Vážený zákazníku,

   na základě Vaší žádosti podané prostřednictvím webového formuláře
na stránkách sdružení dne <?cs var:reqdate ?>, které bylo přiděleno identifikační 
číslo <?cs var:reqid ?>, Vám oznamujeme, že požadovaná žádost o <?cs if:otype == #1 ?>zablokování<?cs elif:otype == #2 ?>odblokování<?cs /if ?>
<?cs if:rtype == #1 ?>změny dat<?cs elif:rtype == #2 ?>transferu k jinému registrátorovi<?cs /if ?> pro <?cs if:type == #3 ?>doménu<?cs elif:type == #1 ?>kontakt s identifikátorem<?cs elif:type == #2 ?>sadu nameserverů s identifikátorem<?cs elif:type == #4 ?>sadu klíčů s identifikátorem<?cs /if ?> <?cs var:handle ?> 
byla úspěšně realizována.  
<?cs if:otype == #1 ?>
U <?cs if:type == #3 ?>domény<?cs elif:type == #1 ?>kontaktu s identifikátorem<?cs elif:type == #2 ?>sady nameserverů s identifikátorem<?cs elif:type == #4 ?>sady klíčů s identifikátorem<?cs /if ?> <?cs var:handle ?> nebude možné provést 
<?cs if:rtype == #1 ?>změnu dat<?cs elif:rtype == #2 ?>transfer k jinému registrátorovi <?cs /if ?> až do okamžiku, kdy tuto blokaci 
zrušíte pomocí příslušného formuláře na stránkách sdružení.
<?cs /if?>
                                             S pozdravem
                                             podpora <?cs var:defaults.company ?>

Information about processing of request

Dear customer,

   based on your request submitted via the web form on the association
pages on <?cs var:reqdate ?>, which received the identification number 
<?cs var:reqid ?>, we are announcing that your request for <?cs if:otype == #1 ?>blocking<?cs elif:otype == #2 ?>unblocking<?cs /if ?>
<?cs if:rtype == #1 ?>data changes<?cs elif:rtype == #2 ?>transfer to other registrar<?cs /if ?> for <?cs if:type == #3 ?>domain name<?cs elif:type == #1 ?>contact with identifier<?cs elif:type == #2 ?>NS set with identifier<?cs elif:type == #4 ?>Keyset with identifier<?cs /if ?> <?cs var:handle ?> 
has been realized.
<?cs if:otype == #1 ?>
No <?cs if:rtype == #1 ?>data changes<?cs elif:rtype == #2 ?>transfer to other registrar<?cs /if ?> of <?cs if:type == #3 ?>domain name<?cs elif:type == #1 ?>contact with identifier<?cs elif:type == #2 ?>NS set with identifier<?cs elif:type == #4 ?>Keyset with identifier<?cs /if ?> <?cs var:handle ?> 
will be possible until you cancel the blocking option using the 
applicable form on association pages. 
<?cs /if?>
                                             Yours sincerely
                                             support <?cs var:defaults.company ?>
' WHERE id=20;


-- STATES ---
CREATE VIEW keyset_states AS
SELECT
  o.id AS object_id,
  o.historyid AS object_hid,
  COALESCE(osr.states,'{}') ||
  CASE WHEN NOT(d.keyset ISNULL) THEN ARRAY[16] ELSE '{}' END ||
  CASE WHEN d.keyset ISNULL 
            AND date_month_test(
              GREATEST(
                COALESCE(l.last_linked,o.crdate)::date,
                COALESCE(ob.update,o.crdate)::date
              ),
              ep_mn.val,ep_tm.val,ep_tz.val
            )
            AND NOT (1 = ANY(COALESCE(osr.states,'{}')))
       THEN ARRAY[17] ELSE '{}' END 
  AS states
FROM
  object ob
  JOIN object_registry o ON (ob.id=o.id AND o.type=4)
  JOIN enum_parameters ep_tm ON (ep_tm.id=9)
  JOIN enum_parameters ep_tz ON (ep_tz.id=10)
  JOIN enum_parameters ep_mn ON (ep_mn.id=11)
  LEFT JOIN (
    SELECT DISTINCT keyset FROM domain
  ) AS d ON (d.keyset=o.id)
  LEFT JOIN (
    SELECT object_id, MAX(valid_to) AS last_linked
    FROM object_state
    WHERE state_id=16 GROUP BY object_id
  ) AS l ON (o.id=l.object_id)
  LEFT JOIN object_state_request_now osr ON (o.id=osr.object_id);

DROP VIEW contact_states;
CREATE VIEW contact_states AS
SELECT
  o.id AS object_id,
  o.historyid AS object_hid,
  COALESCE(osr.states,'{}') ||
  CASE WHEN NOT(cl.cid ISNULL) THEN ARRAY[16] ELSE '{}' END ||
  CASE WHEN cl.cid ISNULL 
            AND date_month_test(
              GREATEST(
                COALESCE(l.last_linked,o.crdate)::date,
                COALESCE(ob.update,o.crdate)::date
              ),
              ep_mn.val,ep_tm.val,ep_tz.val
            )
            AND NOT (1 = ANY(COALESCE(osr.states,'{}')))
       THEN ARRAY[17] ELSE '{}' END 
  AS states
FROM
  object ob
  JOIN object_registry o ON (ob.id=o.id AND o.type=1)
  JOIN enum_parameters ep_tm ON (ep_tm.id=9)
  JOIN enum_parameters ep_tz ON (ep_tz.id=10)
  JOIN enum_parameters ep_mn ON (ep_mn.id=11)
  LEFT JOIN (
    SELECT registrant AS cid FROM domain
    UNION
    SELECT contactid AS cid FROM domain_contact_map
    UNION
    SELECT contactid AS cid FROM nsset_contact_map
    UNION
    SELECT contactid AS cid FROM keyset_contact_map
  ) AS cl ON (o.id=cl.cid)
  LEFT JOIN (
    SELECT object_id, MAX(valid_to) AS last_linked
    FROM object_state
    WHERE state_id=16 GROUP BY object_id
  ) AS l ON (o.id=l.object_id)
  LEFT JOIN object_state_request_now osr ON (o.id=osr.object_id);

CREATE OR REPLACE FUNCTION update_object_states(int)
RETURNS void
AS $$
BEGIN
  IF NOT EXISTS(
    SELECT relname FROM pg_class
    WHERE relname = 'tmp_object_state_change' AND relkind = 'r' AND
    pg_table_is_visible(oid)
  )
  THEN
    CREATE TEMPORARY TABLE tmp_object_state_change (
      object_id INTEGER,
      object_hid INTEGER,
      new_states INTEGER[],
      old_states INTEGER[]
    );
  ELSE
    TRUNCATE tmp_object_state_change;
  END IF;

  IF $1 = 0
  THEN
    INSERT INTO tmp_object_state_change
    SELECT
      st.object_id, st.object_hid, st.states AS new_states, 
      COALESCE(o.states,'{}') AS old_states
    FROM (
      SELECT * FROM domain_states
      UNION
      SELECT * FROM contact_states
      UNION
      SELECT * FROM nsset_states
      UNION
      SELECT * FROM keyset_states
    ) AS st
    LEFT JOIN object_state_now o ON (st.object_id=o.object_id)
    WHERE array_sort_dist(st.states)!=COALESCE(array_sort_dist(o.states),'{}');
  ELSE
    -- domain
    INSERT INTO tmp_object_state_change
    SELECT
      st.object_id, st.object_hid, st.states AS new_states, 
      COALESCE(o.states,'{}') AS old_states
    FROM domain_states st
    LEFT JOIN object_state_now o ON (st.object_id=o.object_id)
    WHERE array_sort_dist(st.states)!=COALESCE(array_sort_dist(o.states),'{}')
    AND st.object_id=$1;
    -- contact
    INSERT INTO tmp_object_state_change
    SELECT
      st.object_id, st.object_hid, st.states AS new_states, 
      COALESCE(o.states,'{}') AS old_states
    FROM contact_states st
    LEFT JOIN object_state_now o ON (st.object_id=o.object_id)
    WHERE array_sort_dist(st.states)!=COALESCE(array_sort_dist(o.states),'{}')
    AND st.object_id=$1;
    -- nsset
    INSERT INTO tmp_object_state_change
    SELECT
      st.object_id, st.object_hid, st.states AS new_states, 
      COALESCE(o.states,'{}') AS old_states
    FROM nsset_states st
    LEFT JOIN object_state_now o ON (st.object_id=o.object_id)
    WHERE array_sort_dist(st.states)!=COALESCE(array_sort_dist(o.states),'{}')
    AND st.object_id=$1;
    -- keyset
    INSERT INTO tmp_object_state_change
    SELECT
      st.object_id, st.object_hid, st.states AS new_states, 
      COALESCE(o.states,'{}') AS old_states
    FROM keyset_states st
    LEFT JOIN object_state_now o ON (st.object_id=o.object_id)
    WHERE array_sort_dist(st.states)!=COALESCE(array_sort_dist(o.states),'{}')
    AND st.object_id=$1;
  END IF;

  INSERT INTO object_state (object_id,state_id,valid_from,ohid_from)
  SELECT c.object_id,e.id,CURRENT_TIMESTAMP,c.object_hid
  FROM tmp_object_state_change c, enum_object_states e
  WHERE e.id = ANY(c.new_states) AND e.id != ALL(c.old_states);

  UPDATE object_state SET valid_to=CURRENT_TIMESTAMP, ohid_to=c.object_hid
  FROM enum_object_states e, tmp_object_state_change c
  WHERE e.id = ANY(c.old_states) AND e.id != ALL(c.new_states)
  AND e.id=object_state.state_id and c.object_id=object_state.object_id 
  AND object_state.valid_to ISNULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION status_update_domain() RETURNS TRIGGER AS $$
  DECLARE
    _num INTEGER;
    _nsset_old INTEGER;
    _registrant_old INTEGER;
    _keyset_old INTEGER;
    _nsset_new INTEGER;
    _registrant_new INTEGER;
    _keyset_new INTEGER;
    _ex_not VARCHAR;
    _ex_dns VARCHAR;
    _ex_let VARCHAR;
--    _ex_reg VARCHAR;
    _proc_tm VARCHAR;
    _proc_tz VARCHAR;
  BEGIN
    _nsset_old := NULL;
    _registrant_old := NULL;
    _keyset_old := NULL;
    _nsset_new := NULL;
    _registrant_new := NULL;
    _keyset_new := NULL;
    SELECT val INTO _ex_not FROM enum_parameters WHERE id=3;
    SELECT val INTO _ex_dns FROM enum_parameters WHERE id=4;
    SELECT val INTO _ex_let FROM enum_parameters WHERE id=5;
--    SELECT val INTO _ex_reg FROM enum_parameters WHERE id=6;
    SELECT val INTO _proc_tm FROM enum_parameters WHERE id=9;
    SELECT val INTO _proc_tz FROM enum_parameters WHERE id=10;
    -- is it INSERT operation
    IF TG_OP = 'INSERT' THEN
      _registrant_new := NEW.registrant;
      _nsset_new := NEW.nsset;
      _keyset_new := NEW.keyset;
      -- we ignore exdate, for new domain it shouldn't influence its state
      -- state: nsset missing
      EXECUTE status_update_state(
        NEW.nsset ISNULL, 14, NEW.id
      );
    -- is it UPDATE operation
    ELSIF TG_OP = 'UPDATE' THEN
      IF NEW.registrant <> OLD.registrant THEN
        _registrant_old := OLD.registrant;
        _registrant_new := NEW.registrant;
      END IF;
      IF COALESCE(NEW.nsset,0) <> COALESCE(OLD.nsset,0) THEN
        _nsset_old := OLD.nsset;
        _nsset_new := NEW.nsset;
      END IF;
      IF COALESCE(NEW.keyset,0) <> COALESCE(OLD.keyset,0) THEN
        _keyset_old := OLD.keyset;
        _keyset_new := NEW.keyset;
      END IF;
      -- take care of all domain statuses
      IF NEW.exdate <> OLD.exdate THEN
        -- at the first sight it seems that there should be checking
        -- for renewProhibited state before setting all of these states
        -- as it's done in global (1. type) views
        -- but the point is that when renewProhibited is set
        -- there is no way to change exdate so this situation can never happen 
        -- state: expiration warning
        EXECUTE status_update_state(
          date_test(NEW.exdate::date,_ex_not),
          8, NEW.id
        );
        -- state: expired
        EXECUTE status_update_state(
          date_test(NEW.exdate::date,'0'),
          9, NEW.id
        );
        -- state: unguarded
        EXECUTE status_update_state(
          date_time_test(NEW.exdate::date,_ex_dns,_proc_tm,_proc_tz), 
          10, NEW.id
        );
        -- state: deleteWarning
        EXECUTE status_update_state(
          date_test(NEW.exdate::date,_ex_let),
          19, NEW.id
        );
        -- state: delete candidate (seems useless - cannot switch after del)
        -- for now delete state will be set only globaly
--        EXECUTE status_update_state(
--          date_time_test(NEW.exdate::date,_ex_reg,_proc_tm,_proc_tz), 
--          17, NEW.id
--        );
      END IF; -- change in exdate
      IF COALESCE(NEW.nsset,0) <> COALESCE(OLD.nsset,0) THEN
        -- state: nsset missing
        EXECUTE status_update_state(
          NEW.nsset ISNULL, 14, NEW.id
        );
      END IF; -- change in nsset
    -- is it DELETE operation
    ELSIF TG_OP = 'DELETE' THEN
      _registrant_old := OLD.registrant;
      _nsset_old := OLD.nsset; -- may be NULL!
      _keyset_old := OLD.keyset; -- may be NULL!
      -- exdate is meaningless when deleting (probably)
    END IF;

    -- add registrant's linked status if there is none
    EXECUTE status_set_state(
      _registrant_new IS NOT NULL, 16, _registrant_new
    );
    -- add nsset's linked status if there is none
    EXECUTE status_set_state(
      _nsset_new IS NOT NULL, 16, _nsset_new
    );
    -- add keyset's linked status if there is none
    EXECUTE status_set_state(
      _keyset_new IS NOT NULL, 16, _keyset_new
    );
    -- remove registrant's linked status if not bound
    -- locking must be done (see comment above)
    IF _registrant_old IS NOT NULL AND 
       status_clear_lock(_registrant_old, 16) IS NOT NULL 
    THEN
      SELECT count(*) INTO _num FROM domain
          WHERE registrant = OLD.registrant;
      IF _num = 0 THEN
        SELECT count(*) INTO _num FROM domain_contact_map
            WHERE contactid = OLD.registrant;
        IF _num = 0 THEN
          SELECT count(*) INTO _num FROM nsset_contact_map
              WHERE contactid = OLD.registrant;
          IF _num = 0 THEN
            SELECT count(*) INTO _num FROM keyset_contact_map
                WHERE contactid = OLD.registrant;
            EXECUTE status_clear_state(_num <> 0, 16, OLD.registrant);
          END IF;
        END IF;
      END IF;
    END IF;
    -- remove nsset's linked status if not bound
    -- locking must be done (see comment above)
    IF _nsset_old IS NOT NULL AND
       status_clear_lock(_nsset_old, 16) IS NOT NULL  
    THEN
      SELECT count(*) INTO _num FROM domain WHERE nsset = OLD.nsset;
      EXECUTE status_clear_state(_num <> 0, 16, OLD.nsset);
    END IF;
    -- remove keyset's linked status if not bound
    -- locking must be done (see comment above)
    IF _keyset_old IS NOT NULL AND
       status_clear_lock(_keyset_old, 16) IS NOT NULL  
    THEN
      SELECT count(*) INTO _num FROM domain WHERE keyset = OLD.keyset;
      EXECUTE status_clear_state(_num <> 0, 16, OLD.keyset);
    END IF;
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION status_update_contact_map() RETURNS TRIGGER AS $$
  DECLARE
    _num INTEGER;
    _contact_old INTEGER;
    _contact_new INTEGER;
  BEGIN
    _contact_old := NULL;
    _contact_new := NULL;
    -- is it INSERT operation
    IF TG_OP = 'INSERT' THEN
      _contact_new := NEW.contactid;
    -- is it UPDATE operation
    ELSIF TG_OP = 'UPDATE' THEN
      IF NEW.contactid <> OLD.contactid THEN
        _contact_old := OLD.contactid;
        _contact_new := NEW.contactid;
      END IF;
    -- is it DELETE operation
    ELSIF TG_OP = 'DELETE' THEN
      _contact_old := OLD.contactid;
    END IF;

    -- add contact's linked status if there is none
    EXECUTE status_set_state(
      _contact_new IS NOT NULL, 16, _contact_new
    );
    -- remove contact's linked status if not bound
    -- locking must be done (see comment above)
    IF _contact_old IS NOT NULL AND
       status_clear_lock(_contact_old, 16) IS NOT NULL 
    THEN
      SELECT count(*) INTO _num FROM domain WHERE registrant = OLD.contactid;
      IF _num = 0 THEN
        SELECT count(*) INTO _num FROM domain_contact_map
            WHERE contactid = OLD.contactid;
        IF _num = 0 THEN
          SELECT count(*) INTO _num FROM nsset_contact_map
              WHERE contactid = OLD.contactid;
          IF _num = 0 THEN
            SELECT count(*) INTO _num FROM keyset_contact_map
                WHERE contactid = OLD.contactid;
            EXECUTE status_clear_state(_num <> 0, 16, OLD.contactid);
          END IF;
        END IF;
      END IF;
    END IF;
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_keyset_contact_map AFTER INSERT OR DELETE OR UPDATE
  ON keyset_contact_map FOR EACH ROW 
  EXECUTE PROCEDURE status_update_contact_map();

--- update object states table for keyset
update enum_object_states set types = types || array[4] where 2 = any (types);

--- update notification map
INSERT INTO notify_statechange_map VALUES (11, 17, 4, 14, 1);

--- update version
update enum_parameters set val='2.0.0' where id=1;

--- all done!
