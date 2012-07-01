---
--- Logger requests for registrar groups manipulation
---
INSERT INTO request_type (id, status, service) VALUES (1336, 'CreateRegistrarGroup', 4);
INSERT INTO request_type (id, status, service) VALUES (1337, 'DeleteRegistrarGroup', 4);
INSERT INTO request_type (id, status, service) VALUES (1338, 'UpdateRegistrarGroup', 4);

---
--- #4344, #4328
---

UPDATE request_property_value rv SET name_id = 
        (SELECT id FROM request_property WHERE name='handle') 
  FROM request r 
  WHERE r.id=rv.entry_id AND  name_id = 
        (SELECT id FROM request_property WHERE name='checkId') 
    AND r.action_type IN 
        (SELECT id FROM request_type WHERE status IN ('NSsetCheck', 'KeysetCheck', 'DomainCheck', 'ContactCheck'));


UPDATE request_property_value rv SET name_id = 
        (SELECT id FROM request_property WHERE name='handle') 
  FROM request r 
  WHERE r.id=rv.entry_id AND  name_id = 
        (SELECT id FROM request_property WHERE name='id') 
    AND r.action_type IN 
        (SELECT id FROM request_type WHERE status IN ('ContactInfo', 'KeysetInfo', 'NSsetInfo', 'NSsetCreate', 'KeysetCreate', 'ContactCreate', 
'NSsetUpdate', 'KeysetUpdate', 'ContactUpdate', 'ContactDelete', 'KeysetDelete', 'NSsetDelete', 'DomainDelete', 'ContactTransfer', 'KeysetTransfer', 'NSsetTransfer', 'DomainTransfer'));


UPDATE request_property_value rv SET name_id = 
        (SELECT id FROM request_property WHERE name='handle') 
  FROM request r 
  WHERE r.id=rv.entry_id AND  name_id = 
        (SELECT id FROM request_property WHERE name='name') 
    AND r.action_type IN 
        (SELECT id FROM request_type WHERE status IN ('DomainCreate', 'DomainTransfer', 'DomainRenew', 'DomainUpdate', 'DomainInfo'));

