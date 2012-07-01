

---
--- Ticket #5113 - long property names from Daphne
---

--
-- how did it look before:
--
--155: 'filter_RequestPropertyValue.Na' 
--156: 'filter_RequestPropertyValue.Va'
--170: 'filter_NSSet.TechContact.Handl'
--181: 'filter_Registrant.Registrar.Or'
--182: 'filter_Registrant.Organization'
--

UPDATE request_property_name SET name='filter_RequestPropertyValue.Name' WHERE id=155;
UPDATE request_property_name SET name='filter_RequestPropertyValue.Value' WHERE id=156;
UPDATE request_property_name SET name='filter_NSSet.TechContact.Handle' WHERE id=170;
UPDATE request_property_name SET name='filter_Registrant.Registrar.Organization' WHERE id=181;
UPDATE request_property_name SET name='filter_Registrant.Organization' WHERE id=182;




