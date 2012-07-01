--- update version
UPDATE enum_parameters SET val='2.1.1' WHERE id=1;

--- add index for searching keysets
CREATE INDEX object_registry_upper_name_4_idx 
 ON object_registry (UPPER(name)) WHERE type=4;

--- add index for searching through mails by crdate
CREATE INDEX mail_archive_crdate_idx ON mail_archive (crdate);

