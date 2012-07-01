---
--- don't forget to update database schema version
---

UPDATE enum_parameters SET val = '2.5.1' WHERE id = 1;


---
--- #4790 - set contact disclose not null (run before schema change)
---

UPDATE contact SET disclosename = TRUE WHERE disclosename IS NULL;
UPDATE contact SET discloseorganization = TRUE WHERE discloseorganization IS NULL;
UPDATE contact SET discloseaddress = TRUE WHERE discloseaddress IS NULL;
UPDATE contact SET disclosetelephone = FALSE WHERE disclosetelephone IS NULL;
UPDATE contact SET disclosefax = FALSE WHERE disclosefax IS NULL;
UPDATE contact SET discloseemail = FALSE WHERE discloseemail IS NULL;
UPDATE contact SET disclosevat = FALSE WHERE disclosevat IS NULL;
UPDATE contact SET discloseident = FALSE WHERE discloseident IS NULL;
UPDATE contact SET disclosenotifyemail = FALSE WHERE disclosenotifyemail IS NULL;

UPDATE contact_history SET disclosename = TRUE WHERE disclosename IS NULL;
UPDATE contact_history SET discloseorganization = TRUE WHERE discloseorganization IS NULL;
UPDATE contact_history SET discloseaddress = TRUE WHERE discloseaddress IS NULL;
UPDATE contact_history SET disclosetelephone = FALSE WHERE disclosetelephone IS NULL;
UPDATE contact_history SET disclosefax = FALSE WHERE disclosefax IS NULL;
UPDATE contact_history SET discloseemail = FALSE WHERE discloseemail IS NULL;
UPDATE contact_history SET disclosevat = FALSE WHERE disclosevat IS NULL;
UPDATE contact_history SET discloseident = FALSE WHERE discloseident IS NULL;
UPDATE contact_history SET disclosenotifyemail = FALSE WHERE disclosenotifyemail IS NULL;

