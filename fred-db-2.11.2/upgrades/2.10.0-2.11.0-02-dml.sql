---
--- don't forget to update database schema version
---
UPDATE enum_parameters SET val = '2.11.0' WHERE id = 1;


---
--- Ticket #6298
---
INSERT INTO invoice_type (id, name) VALUES (0, 'advance');
INSERT INTO invoice_type (id, name) VALUES (1, 'account');

SELECT setval('invoice_type_id_seq', 1);

INSERT INTO invoice_number_prefix
    (prefix, zone_id, invoice_type_id)
    VALUES (24,
            (SELECT id FROM zone WHERE fqdn = 'cz'),
            (SELECT id FROM invoice_type WHERE name = 'advance')
           );

INSERT INTO invoice_number_prefix
    (prefix, zone_id, invoice_type_id)
    VALUES (23,
            (SELECT id FROM zone WHERE fqdn = 'cz'),
            (SELECT id FROM invoice_type WHERE name = 'account')
           );

INSERT INTO invoice_number_prefix
    (prefix, zone_id, invoice_type_id)
    VALUES (11,
            (SELECT id FROM zone WHERE fqdn = '0.2.4.e164.arpa'),
            (SELECT id FROM invoice_type WHERE name = 'advance')
           );

INSERT INTO invoice_number_prefix
    (prefix, zone_id, invoice_type_id)
    VALUES (12,
            (SELECT id FROM zone WHERE fqdn = '0.2.4.e164.arpa'),
            (SELECT id FROM invoice_type WHERE name = 'account')
           );

