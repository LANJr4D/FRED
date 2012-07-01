---
--- don't forget to update database schema version
---
UPDATE enum_parameters SET val = '2.4.0' WHERE id = 1;



---
--- Ticket #3914
--- filemanager's file for certification evaluation pdf 
---
INSERT INTO enum_filetype (id, name) VALUES (6, 'certification evaluation pdf');



---
--- Ticket #4113
--- initialization of 'certified' list of registrars
---
INSERT INTO registrar_group (short_name) VALUES ('certified');
INSERT INTO registrar_group (short_name) VALUES ('uncertified');

INSERT INTO registrar_group_map (registrar_id, registrar_group_id, member_from)
SELECT DISTINCT registrarid,
       (SELECT id FROM registrar_group WHERE short_name = 'certified'),
       CURRENT_DATE 
  FROM (SELECT r.id AS registrarid 
          FROM registrar r 
               JOIN registrarinvoice ri ON ri.registrarid = r.id 
               JOIN zone z ON z.id = ri.zone 
         WHERE ri.fromdate <= CURRENT_DATE 
               AND (todate >= CURRENT_DATE OR todate IS NULL) 
               AND z.fqdn = 'cz' OR z.fqdn = '0.2.4.e164.arpa') AS riz;



---
--- Ticket #3797
---
-- state: outzoneUnguarded, obj: domain, 
-- template: expiration_dns_owner, emails: generic emails (like kontakt@... postmaster@... info@...)
INSERT INTO notify_statechange_map VALUES (12, 20, 3, 4, 3);



---
--- Ticket #3885 - new keyset algorithms
---
UPDATE enum_reason SET reason = 'Field ``alg'''' must be 1,2,3,4,5,6,7,8,10,12,252,253,254 or 255',
                       reason_cs = 'Pole ``alg'''' musí být 1,2,3,4,5,6,7,8,10,12,252,253,254 nebo 255'
                WHERE id = 56;



---
--- notify letters - postservice
---
INSERT INTO enum_send_status (id, description) VALUES (1, 'Ready for processing/sending');
INSERT INTO enum_send_status (id, description) VALUES (2, 'Waiting for manual confirmation of sending');
INSERT INTO enum_send_status (id, description) VALUES (3, 'No automatic processing');
INSERT INTO enum_send_status (id, description) VALUES (4, 'Delivery failed');
INSERT INTO enum_send_status (id, description) VALUES (5, 'Successfully sent');
INSERT INTO enum_send_status (id, description) VALUES (6, 'In processing, don''t touch');

INSERT INTO letter_archive (status , file_id) SELECT DISTINCT 5, file_id FROM notify_letters WHERE file_id IS NOT NULL;

UPDATE notify_letters nl SET letter_id = la.id FROM letter_archive la WHERE la.file_id = nl.file_id;

