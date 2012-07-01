---
--- don't forget to update database schema version
---
UPDATE enum_parameters SET val = '2.8.0' WHERE id = 1;


---
--- inserting new poll message type
---
INSERT INTO messagetype (id, name) VALUES (16, 'request_fee_info');

---
--- general registry operation used in price_list entry for request charging
---
INSERT INTO enum_operation (id, operation) VALUES (3, 'GeneralEppOperation');
INSERT INTO request_fee_parameter (id, valid_from, count_free_base, count_free_per_domain) VALUES (1, '2011-05-31 22:00:00', 25000, 100);
INSERT INTO price_list (zone, operation, valid_from, price, period) SELECT id, 3, '2011-05-31 22:00:00', 0.1, 0  FROM zone WHERE fqdn='cz';

---
--- #5583 - typo
---
UPDATE enum_object_states SET name = 'serverRenewProhibited' WHERE name = 'serverRenewProhibited ';

