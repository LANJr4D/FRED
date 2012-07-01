---
--- UPGRADE SCRIPT 2.2.0 -> 2.3.0 (data modification part)
---

---
--- dont forget to update database schema version
---
UPDATE enum_parameters SET val = '2.3.0' WHERE id = 1;

---
--- Ticket #1670 Banking refactoring
---

INSERT INTO enum_bank_code (name_full,name_short,code) VALUES ('Fio, družstevní záložna', 'FIOZ', '2010');
UPDATE bank_account SET balance = 0.0 WHERE balance IS NULL;

INSERT INTO bank_account VALUES (DEFAULT, NULL, '36153615', 'Akademie', '0300', 0, NULL, NULL);

---
--- data migration
---

--- duplicity statement :(
DELETE FROM bank_statement_item WHERE statement_id = 46;
DELETE FROM bank_statement_head WHERE id = 46;

--- bank_statement_head -> bank_statement
INSERT INTO bank_statement
                           (id, account_id, num, create_date, balance_old_date,
                            balance_old, balance_new, balance_credit, balance_debet,
                            file_id)

    SELECT id, account_id, num, create_date, balance_old_date, balance_old, balance_new,
           balance_credit, balance_debet, NULL
       FROM bank_statement_head
      ORDER BY id;

--- bank_statement_item && bank_ebanka_list -> bank_payement
--- (should be ordered by account_date or not?, crtime set to NOW()?)
INSERT INTO bank_payment
                         (statement_id, account_id, account_number, bank_code,
                          code, type, status, konstsym, varsymb, specsymb,
                          price, account_evid, account_date, account_memo,
                          invoice_id, account_name, crtime)

        SELECT NULL, ebanka.account_id, trim(both ' ' from ebanka.account_number),
                trim(both ' ' from ebanka.bank_code), 1, 1, 1,
                trim(both ' ' from ebanka.konstsym), trim(both from ebanka.varsymb),
                NULL, ebanka.price, trim(both ' ' from ebanka.ident) as account_evid,
                ebanka.crdate::timestamptz AT TIME ZONE 'Europe/Prague' AS account_date, 
                trim(both ' ' from ebanka.memo),
                ebanka.invoice_id, trim(both ' ' from ebanka.name), NOW()
           FROM bank_ebanka_list ebanka
        UNION ALL
        SELECT csob.statement_id,
               (SELECT ba.id
                   FROM bank_account ba
                  WHERE ba.account_number = '188208275' AND ba.bank_code = '0300' LIMIT 1
               ),
               ltrim(trim(both ' ' from csob.account_number), '0'), trim(both ' ' from csob.bank_code),
               1, 1, 1, trim(both ' ' from csob.konstsym), ltrim(trim(both ' ' from csob.varsymb), '0'),
               ltrim(trim(both ' ' from csob.specsymb), '0'), csob.price,
               ltrim(substring(trim(both ' ' from csob.account_evid), 5), '0') as account_evid,
               csob.account_date AS account_date, trim(both ' ' from csob.account_memo), csob.invoice_id, NULL,
               NOW()
           FROM bank_statement_item csob
          ORDER BY account_date, account_evid;


SELECT setval('bank_payment_id_seq', (SELECT max(id) FROM bank_payment));
SELECT setval('bank_statement_id_seq', (SELECT max(id) FROM bank_statement));

UPDATE bank_payment SET type = 2 WHERE invoice_id IS NOT NULL;

---
--- Fix account_memo and specsymb fields for csob payments
---

UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'EURODNS - zaloha ENUM registrace'), account_name = trim(both ' ' FROM 'CZ.NIC, Z.S.P.O.') WHERE account_evid = '15';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '741';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM '67985726'), account_memo = trim(both ' ' FROM 'presun mezi ucty'), account_name = trim(both ' ' FROM 'CZ.NIC, Z.S.P.O.') WHERE account_evid = '34';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.'), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '742';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '743';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '744';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '745';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '746';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '749';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '750';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '753';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '754';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '755';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'TELEKOM AUSTRIA CZEC') WHERE account_evid = '757';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '758';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '759';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '760';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '761';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '762';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '763';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '764';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '765';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '766';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '767';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '768';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '769';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '770';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '771';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '772';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '773';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '774';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '775';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '776';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '777';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '778';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '779';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '780';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '781';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '782';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '783';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '784';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.'), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '785';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '786';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '787';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '790';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '791';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '792';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '793';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '794';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '795';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '796';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'TELEKOM AUSTRIA CZEC') WHERE account_evid = '797';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '798';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '801';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '802';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '803';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '804';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '805';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '806';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '807';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '808';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '809';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '810';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '812';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '813';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '814';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '815';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '816';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '817';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '818';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '819';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '820';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '821';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.   '), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '822';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '825';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '826';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '827';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '828';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '829';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '830';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '831';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '832';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '833';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '834';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '835';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.   '), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '836';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '837';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '838';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '839';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '840';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '841';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '842';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '843';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '844';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'IPEX A.S.') WHERE account_evid = '845';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '846';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'VOLNY, A.S.') WHERE account_evid = '847';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.   '), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '848';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '849';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '850';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '853';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '854';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '855';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '856';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '857';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '858';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '859';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '860';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.   '), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '861';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '862';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '863';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '864';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '865';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '866';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '867';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '868';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'IPEX A.S.') WHERE account_evid = '869';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '870';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '871';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '872';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '873';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '874';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '875';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.   '), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '876';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZ-NIC / Gransy s.r.o.             '), account_name = trim(both ' ' FROM 'GRANSY S.R.O.') WHERE account_evid = '877';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '878';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '879';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '880';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '883';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '884';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '38';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '885';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '886';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.   '), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '887';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '888';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '889';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '890';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '891';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '892';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '893';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '894';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '895';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '896';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '897';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '898';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'VOLNY, A.S.') WHERE account_evid = '901';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '902';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'IPEX A.S.') WHERE account_evid = '903';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '904';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.   '), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '905';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '906';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '907';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '908';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '909';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '910';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '911';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '912';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '913';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.   '), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '914';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '915';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '916';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '917';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '918';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '919';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '920';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '921';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '922';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '923';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '926';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '927';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '928';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'NEW MEDIA GROUP S.R.') WHERE account_evid = '929';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '930';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM '67985726'), account_memo = trim(both ' ' FROM 'GANDI - kredit                     prevod mezi ucty'), account_name = trim(both ' ' FROM 'CZ.NIC, Z.S.P.O.') WHERE account_evid = '931';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM '67985726'), account_memo = trim(both ' ' FROM 'INSTRA - kredit                    prevod mezi ucty'), account_name = trim(both ' ' FROM 'CZ.NIC, Z.S.P.O.') WHERE account_evid = '932';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.   '), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '933';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '934';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'GRANSY S.R.O.') WHERE account_evid = '935';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '936';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '937';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '938';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '939';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '940';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '941';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '942';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '943';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.   '), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '944';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '945';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '946';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '947';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '948';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '949';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '950';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '951';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '952';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '955';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '956';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '957';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.   '), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '958';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '959';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '960';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '961';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '962';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '963';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '964';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '965';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'VOLNY, A.S.') WHERE account_evid = '966';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '967';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '968';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '969';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '970';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '971';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.   '), account_name = trim(both ' ' FROM 'Web4U s. r. o.') WHERE account_evid = '972';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '973';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '974';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '975';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '978';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '979';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '980';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '981';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '982';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '983';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '984';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'GRANSY S.R.O.') WHERE account_evid = '985';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '986';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '987';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '988';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '989';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '990';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '991';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '992';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '993';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '994';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '995';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'VOLNY, A.S.') WHERE account_evid = '996';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '997';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '998';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1001';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1002';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1003';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1004';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1005';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1006';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.   '), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '1007';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1008';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM '                                   '), account_name = trim(both ' ' FROM 'IPEX A.S.') WHERE account_evid = '1009';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1010';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1013';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1014';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1015';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1016';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC                              '), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1017';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1018';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1019';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1020';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1021';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1022';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1023';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1024';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1025';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'VOLNY, A.S.') WHERE account_evid = '1026';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1027';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1028';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '1029';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1030';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'NMG-CZ.NIC - reg. poplatky'), account_name = trim(both ' ' FROM 'NEW MEDIA GROUP S.R.') WHERE account_evid = '1031';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.'), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '1032';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1033';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1035';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '1036';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1037';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1038';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1039';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1040';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '1043';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1044';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1045';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1046';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1047';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1048';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1049';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1050';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1051';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1052';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '1053';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1054';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1055';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1056';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1057';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.'), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '1058';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1061';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1062';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1063';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '1064';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'NEW MEDIA GROUP S.R.') WHERE account_evid = '1065';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1066';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '1069';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1070';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1071';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1072';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'NEW MEDIA GROUP S.R.') WHERE account_evid = '1073';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1074';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1075';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1076';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1077';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'PYORD000007878160193336'), account_name = trim(both ' ' FROM 'TELEFONICA O2 CZECH') WHERE account_evid = '1078';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1079';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1080';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1081';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1082';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1083';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1084';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1085';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1086';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1087';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1088';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1089';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1090';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1091';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1092';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1093';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1094';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1095';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1096';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'GRANSY S.R.O.') WHERE account_evid = '1097';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1098';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1099';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'Zaloha registratora Web4U s.r.o.'), account_name = trim(both ' ' FROM 'WEB4U') WHERE account_evid = '1100';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1101';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1102';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1105';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1106';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1107';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1108';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '1109';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1110';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1111';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1112';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1113';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '1114';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1115';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1116';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1117';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '1118';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1119';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1120';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1121';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1122';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1123';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '1124';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1125';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1126';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1127';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '1128';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1129';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1130';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1131';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1132';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '1133';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1134';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1135';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM 'CZNIC'), account_name = trim(both ' ' FROM 'ZONER SOFTWARE,S.R.O') WHERE account_evid = '1136';
UPDATE bank_payment SET specsymb = trim(both ' ' FROM ''), account_memo = trim(both ' ' FROM ''), account_name = trim(both ' ' FROM 'ONE.CZ S.R.O.') WHERE account_evid = '1137';


---
--- Typo fixes
---

---
--- Ticket #3107 - object state description typo
---
UPDATE
    enum_object_states_desc
SET
    description = 'Domain is administratively kept out of zone'
WHERE
    state_id = 5 AND lang = 'EN';


UPDATE
    enum_object_states_desc
SET
    description = 'Domain is administratively kept in zone'
WHERE
    state_id = 6 AND lang = 'EN';

---
--- Upgrade to fixes from SVN r8467 and r9590 - Fix typos
---

UPDATE
    enum_object_states_desc
SET
    description = 'Není povoleno prodloužení registrace objektu'
WHERE
    state_id = 2 AND lang = 'CS';

UPDATE
    enum_object_states_desc
SET
    description = 'Registration renewal prohibited'
WHERE
    state_id = 2 AND lang = 'EN';



UPDATE
    enum_reason
SET
    reason = 'bad format of contact handle'
WHERE
    id = 1;

UPDATE
    enum_reason
SET
    (reason, reason_cs) = ('bad format of nsset handle', 'neplatný formát ukazatele nssetu')
WHERE
    id = 2;

UPDATE
    enum_reason
SET
    reason_cs = 'neplatný formát názvu domény'
WHERE
    id = 3;

UPDATE
    enum_reason
SET
    (reason, reason_cs) = ('within protection period.', 'je v ochranné lhůtě')
WHERE
    id = 7;

UPDATE
    enum_reason
SET
    reason_cs = 'neplatná IP adresa'
WHERE
    id = 8;

UPDATE
    enum_reason
SET
    reason_cs = 'neplatný formát názvu jmenného serveru DNS'
WHERE
    id = 9;

UPDATE
    enum_reason
SET
    reason_cs = 'duplicitní adresa jmenného serveru DNS'
WHERE
    id = 10;

UPDATE
    enum_reason
SET
    reason_cs = 'nepovolená  IP adresa glue záznamu'
WHERE
    id = 11;

UPDATE
    enum_reason
SET
    reason_cs = 'jsou zapotřebí alespoň dva DNS servery'
WHERE
    id = 12;

UPDATE
    enum_reason
SET
    reason_cs = 'perioda je nad maximální dovolenou hodnotou'
WHERE
    id = 14;

UPDATE
    enum_reason
SET
    reason_cs = 'perioda neodpovídá dovolenému intervalu'
WHERE
    id = 15;

UPDATE
    enum_reason
SET
    reason_cs = 'neznámé msgID'
WHERE
    id = 17;

UPDATE
    enum_reason
SET
    reason_cs = 'datum vypršení platnosti se nepoužívá'
WHERE
    id = 18;

UPDATE
    enum_reason
SET
    reason_cs = 'nelze odstranit jmenný server DNS'
WHERE
    id = 21;

UPDATE
    enum_reason
SET
    reason_cs = 'nelze přidat jmenný server DNS'
WHERE
    id = 22;

UPDATE
    enum_reason
SET
    (reason, reason_cs) = ('Can not remove technical contact', 'nelze vymazat technický kontakt')
WHERE
    id = 23;

UPDATE
    enum_reason
SET
    reason = 'Technical contact does not exist'
WHERE
    id = 25;

UPDATE
    enum_reason
SET
    reason_cs = 'Administrátorský kontakt je již přiřazen k tomuto objektu'
WHERE
    id = 26;

UPDATE
    enum_reason
SET
    (reason, reason_cs) = ('Administrative contact does not exist', 'Administrátorský kontakt neexistuje')
WHERE
    id = 27;

UPDATE
    enum_reason
SET
    (reason, reason_cs) = ('nsset handle does not exist.', 'sada jmenných serverů není vytvořena')
WHERE
    id = 28;

UPDATE
    enum_reason
SET
    reason_cs = 'jmenný server DNS je již přiřazen sadě jmenných serverů'
WHERE
    id = 30;

UPDATE
    enum_reason
SET
    reason_cs = 'jmenný server DNS není přiřazen sadě jmenných serverů'
WHERE
    id = 31;

UPDATE
    enum_reason
SET
    (reason, reason_cs) = ('Registration is prohibited', 'Registrace je zakázána')
WHERE
    id = 36;

UPDATE
    enum_reason
SET
    reason = 'Bad format of keyset handle'
WHERE
    id = 39;

UPDATE
    enum_reason
SET
    reason = 'Keyset handle does not exist'
WHERE
    id = 40;

UPDATE
    enum_reason
SET
    reason = 'DSRecord is not set for this keyset'
WHERE
    id = 45;

UPDATE
    enum_reason
SET
    reason = 'Digest must be 40 characters long'
WHERE
    id = 47;

UPDATE
    enum_reason
SET
    reason = 'Object does not belong to the registrar'
WHERE
    id = 48;

UPDATE
    enum_reason
SET
    reason = 'Too many nameservers in this nsset'
WHERE
    id = 52;

UPDATE
    enum_reason
SET
    reason_cs = 'Pole ``flags'''' musí být 0, 256 nebo 257'
WHERE
    id = 54;

UPDATE
    enum_reason
SET
    reason = 'Field ``key'''' contains invalid character'
WHERE
    id = 58;

UPDATE
    enum_reason
SET
    reason = 'DNSKey does not exist for this keyset'
WHERE
    id = 60;




UPDATE
    mail_templates
SET
    template = 
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

   If you did not submit the aforementioned request, please notify us about
this fact at the following address <?cs var:defaults.emailsupport ?>.


                                             Yours sincerely
                                             support <?cs var:defaults.company ?>
'
WHERE
    id = 1;


UPDATE
    mail_templates
SET
    template = 
' English version of the e-mail is entered below the Czech version

Zaslání autorizační informace

Vážený zákazníku,

   na základě Vaší žádosti, podané prostřednictvím registrátora
<?cs var:registrar ?>, Vám zasíláme požadované heslo
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
we are sending the requested password that belongs to
the <?cs if:type == #3 ?>domain name<?cs elif:type == #1 ?>contact with identifier<?cs elif:type == #2 ?>NS set with identifier<?cs elif:type == #4 ?>Keyset with identifier<?cs /if ?> <?cs var:handle ?>.

   The password is: <?cs var:authinfo ?>

   This message is being sent only to the e-mail address that we have on file
for a particular person in the Central Registry of Domain Names.

   If you did not submit the aforementioned request, please notify us about
this fact at the following address <?cs var:defaults.emailsupport ?>.


                                             Yours sincerely
                                             support <?cs var:defaults.company ?>
'
WHERE
    id = 2;


---
--- Ticket #3477
---

UPDATE mail_templates SET template =
'
Výsledek technické kontroly sady nameserverů <?cs var:handle ?>
Result of technical check on NS set <?cs var:handle ?>

Datum kontroly / Date of the check: <?cs var:checkdate ?>
Typ kontroly / Control type : periodická / periodic 
Číslo kontroly / Ticket: <?cs var:ticket ?>

<?cs def:printtest(par_test) ?><?cs if:par_test.name == "existence" ?>Následující nameservery v sadě nameserverů nejsou dosažitelné:
Following nameservers in NS set are not reachable:
<?cs each:ns = par_test.ns ?>    <?cs var:ns ?>
<?cs /each ?><?cs /if ?><?cs if:par_test.name == "autonomous" ?>Sada nameserverů neobsahuje minimálně dva nameservery v různých
autonomních systémech.
In NS set are no two nameservers in different autonomous systems.

<?cs /if ?><?cs if:par_test.name == "presence" ?><?cs each:ns = par_test.ns ?>Nameserver <?cs var:ns ?> neobsahuje záznam pro domény:
Nameserver <?cs var:ns ?> does not contain record for domains:
<?cs each:fqdn = ns.fqdn ?>    <?cs var:fqdn ?>
<?cs /each ?><?cs if:ns.overfull ?>    ...
<?cs /if ?><?cs /each ?><?cs /if ?><?cs if:par_test.name == "authoritative" ?><?cs each:ns = par_test.ns ?>Nameserver <?cs var:ns ?> není autoritativní pro domény:
Nameserver <?cs var:ns ?> is not authoritative for domains:
<?cs each:fqdn = ns.fqdn ?>    <?cs var:fqdn ?>
<?cs /each ?><?cs if:ns.overfull ?>    ...
<?cs /if ?><?cs /each ?><?cs /if ?><?cs if:par_test.name == "heterogenous" ?>Všechny nameservery v sadě nameserverů používají stejnou implementaci
DNS serveru.
All nameservers in NS set use the same implementation of DNS server.

<?cs /if ?><?cs if:par_test.name == "notrecursive" ?>Následující nameservery v sadě nameserverů jsou rekurzivní:
Following nameservers in NS set are recursive:
<?cs each:ns = par_test.ns ?>    <?cs var:ns ?>
<?cs /each ?><?cs /if ?><?cs if:par_test.name == "notrecursive4all" ?>Následující nameservery v sadě nameserverů zodpověděly rekurzivně dotaz:
Following nameservers in NS set answered recursively a query:
<?cs each:ns = par_test.ns ?>    <?cs var:ns ?>
<?cs /each ?><?cs /if ?><?cs if:par_test.name == "dnsseckeychase" ?>Pro následující domény přislušející sadě nameserverů nebylo možno 
sestavit řetěz důvěry:
For following domains belonging to NS set was unable to create 
key chain of trust:
<?cs each:domain = par_test.ns ?>    <?cs var:domain ?>
<?cs /each ?><?cs /if ?><?cs /def ?>
=== Chyby / Errors ==================================================

<?cs each:item = tests ?><?cs if:item.type == "error" ?><?cs call:printtest(item) ?><?cs /if ?><?cs /each ?>
=== Varování / Warnings =============================================

<?cs each:item = tests ?><?cs if:item.type == "warning" ?><?cs call:printtest(item) ?><?cs /if ?><?cs /each ?>
=== Upozornění / Notice =============================================

<?cs each:item = tests ?><?cs if:item.type == "notice" ?><?cs call:printtest(item) ?><?cs /if ?><?cs /each ?>
=====================================================================


                                             S pozdravem
                                             podpora <?cs var:defaults.company ?>
' WHERE id = 16;


