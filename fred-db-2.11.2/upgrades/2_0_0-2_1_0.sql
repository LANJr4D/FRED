CREATE TABLE dnskey (
    id serial PRIMARY KEY,
    keysetid integer REFERENCES Keyset(id) ON UPDATE CASCADE NOT NULL,
    flags integer NOT NULL,
    protocol integer NOT NULL,
    alg integer NOT NULL,
    key text NOT NULL
);

comment on table dnskey is '';
comment on column dnskey.id is 'unique automatically generated identifier';
comment on column dnskey.keysetid is 'reference to relevant record in keyset table';
comment on column dnskey.flags is '';
comment on column dnskey.protocol is 'must be 3';
comment on column dnskey.alg is 'used algorithm (see http://rfc-ref.org/RFC-TEXTS/4034/chapter11.html for further details)';
comment on column dnskey.key is 'base64 decoded key';

CREATE TABLE dnskey_history (
    historyid integer REFERENCES History,
    id integer NOT NULL,
    keysetid integer NOT NULL,
    flags integer NOT NULL,
    protocol integer NOT NULL,
    alg integer NOT NULL,
    key text NOT NULL,
    PRIMARY KEY (historyid, id)
);

comment on table dnskey_history is 'historic data from dnskey table';

INSERT INTO enum_reason VALUES (48, 'Object do not belong to registrar', 'Objekt nepatří registrátorovi');
INSERT INTO enum_reason VALUES (49, 'Too many technical administrators contacts.', 'Příliš mnoho administrátorských kontaktů');
INSERT INTO enum_reason VALUES (50, 'Too many DS records', 'Příliš mnoho DS záznamů');
INSERT INTO enum_reason VALUES (51, 'Too many DNSKEY records', 'Příliš mnoho DNSKEY záznamů');

INSERT INTO enum_reason VALUES (52, 'Too many Nameservers in this nsset', 'Příliš mnoho jmenných serverů DNS je přiřazeno sadě jmenných serverů');
INSERT INTO enum_reason VALUES (53, 'No DNSKey record', 'Žádný DNSKey záznam');
INSERT INTO enum_reason VALUES (54, 'Field ``flags'''' must be 0, 256 or 257', 'Pole ``flags'''' musí bý 0, 256 nebo 257');
INSERT INTO enum_reason VALUES (55, 'Field ``protocol'''' must be 3', 'Pole ``protocol'''' musí být 3');
INSERT INTO enum_reason VALUES (56, 'Field ``alg'''' must be 1,2,3,4,5,252,253,254 or 255', 'Pole ``alg'''' musí být 1,2,3,4,5,252,253,254 nebo 255');
INSERT INTO enum_reason VALUES (57, 'Field ``key'''' has invalid length', 'Pole ``key'''' má špatnou délku');
INSERT INTO enum_reason VALUES (58, 'Field ``key'''' contain invalid character', 'Pole ``key'''' obsahuje neplatný znak');
INSERT INTO enum_reason VALUES (59, 'DNSKey already exists for this keyset', 'DNSKey již pro tento keyset existuje');
INSERT INTO enum_reason VALUES (60, 'DNSKey not exists for this keyset', 'DNSKey pro tento keyset neexistuje');
INSERT INTO enum_reason VALUES (61, 'Duplicity DNSKey', 'Duplicitní DNSKey');
INSERT INTO enum_reason VALUES (62, 'Keyset must have DNSKey or DSRecord', 'Keyset musí mít DNSKey nebo DSRecord');

SELECT setval('enum_reason_id_seq', 62);

SELECT setval('enum_action_id_seq', 1106); 

--- update version
update enum_parameters set val='2.1.0' where id=1;
