---
--- Ticket #3262 (#3747)
--- registrar certification
---
CREATE DOMAIN classification_type AS integer NOT NULL
	CONSTRAINT classification_type_check CHECK (VALUE IN (0, 1, 2, 3, 4, 5)); 

COMMENT ON DOMAIN classification_type 
	IS 'allowed values of classification for registrar certification';

CREATE TABLE registrar_certification
(
    id serial PRIMARY KEY, -- certification id
    registrar_id integer NOT NULL REFERENCES registrar(id), -- registrar id
    valid_from date NOT NULL, --  registrar certification valid from
    valid_until date NOT NULL, --  registrar certification valid until = valid_from + 1year
    classification classification_type NOT NULL, -- registrar certification result checked 0-5
    eval_file_id integer NOT NULL REFERENCES files(id) -- link to pdf file
);

-- check whether registrar_certification life is valid
CREATE OR REPLACE FUNCTION registrar_certification_life_check() 
RETURNS "trigger" AS $$
DECLARE
    last_reg_cert RECORD;
BEGIN
    IF NEW.valid_from > NEW.valid_until THEN
        RAISE EXCEPTION 'Invalid registrar certification life: valid_from > valid_until';
    END IF;

    IF TG_OP = 'INSERT' THEN
        SELECT * FROM registrar_certification INTO last_reg_cert
            WHERE registrar_id = NEW.registrar_id AND id < NEW.id
            ORDER BY valid_from DESC, id DESC LIMIT 1;
        IF FOUND THEN
            IF last_reg_cert.valid_until > NEW.valid_from  THEN
                RAISE EXCEPTION 'Invalid registrar certification life: last valid_until > new valid_from';
            END IF;
        END IF;
    ELSEIF TG_OP = 'UPDATE' THEN
        IF NEW.valid_from <> OLD.valid_from THEN
            RAISE EXCEPTION 'Change of valid_from not allowed';
        END IF;
        IF NEW.valid_until > OLD.valid_until THEN
            RAISE EXCEPTION 'Certification prolongation not allowed';
        END IF;
        IF NEW.registrar_id <> OLD.registrar_id THEN
            RAISE EXCEPTION 'Change of registrar not allowed';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION registrar_certification_life_check()
	IS 'check whether registrar_certification life is valid'; 

CREATE TRIGGER "trigger_registrar_certification"
  AFTER INSERT OR UPDATE ON registrar_certification
  FOR EACH ROW EXECUTE PROCEDURE registrar_certification_life_check();


CREATE INDEX registrar_certification_valid_from_idx ON registrar_certification(valid_from);
CREATE INDEX registrar_certification_valid_until_idx ON registrar_certification(valid_until);

COMMENT ON TABLE registrar_certification IS 'result of registrar certification';
COMMENT ON COLUMN registrar_certification.registrar_id IS 'certified registrar id';
COMMENT ON COLUMN registrar_certification.valid_from IS
    'certification is valid from this date';
COMMENT ON COLUMN registrar_certification.valid_until IS
    'certification is valid until this date, certification should be valid for 1 year';
COMMENT ON COLUMN registrar_certification.classification IS
    'registrar certification result checked 0-5';
COMMENT ON COLUMN registrar_certification.eval_file_id IS
    'evaluation pdf file link';



---
--- Ticket #3262
--- registrar groups
---
CREATE TABLE registrar_group
(
    id serial PRIMARY KEY, -- registrar group id
    short_name varchar(255) NOT NULL UNIQUE, -- short name of the group
    cancelled timestamp -- when the group was cancelled
);

-- check whether registrar_group is empty and not cancelled
CREATE OR REPLACE FUNCTION cancel_registrar_group_check() RETURNS "trigger" AS $$
DECLARE
    registrars_in_group INTEGER;
BEGIN
    IF OLD.cancelled IS NOT NULL THEN
        RAISE EXCEPTION 'Registrar group already cancelled';
    END IF;

    IF NEW.cancelled IS NOT NULL AND EXISTS(
        SELECT * 
          FROM registrar_group_map 
         WHERE registrar_group_id = NEW.id
          AND registrar_group_map.member_from <= CURRENT_DATE
          AND (registrar_group_map.member_until IS NULL 
                  OR (registrar_group_map.member_until >= CURRENT_DATE 
                          AND  registrar_group_map.member_from 
                              <> registrar_group_map.member_until))) 
    THEN 
        RAISE EXCEPTION 'Unable to cancel non-empty registrar group';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cancel_registrar_group_check()
	IS 'check whether registrar_group is empty and not cancelled'; 

CREATE TRIGGER "trigger_cancel_registrar_group"
  AFTER UPDATE  ON registrar_group
  FOR EACH ROW EXECUTE PROCEDURE cancel_registrar_group_check();


CREATE INDEX registrar_group_short_name_idx ON registrar_group(short_name);

COMMENT ON TABLE registrar_group IS 'available groups of registars';
COMMENT ON COLUMN registrar_group.id IS 'group id';
COMMENT ON COLUMN registrar_group.short_name IS 'group short name';
COMMENT ON COLUMN registrar_group.cancelled IS 'time when the group was cancelled';

CREATE TABLE registrar_group_map
(
    id serial PRIMARY KEY, -- membership of registrar in group id
    registrar_id integer NOT NULL REFERENCES registrar(id), -- registrar id
    registrar_group_id integer NOT NULL REFERENCES registrar_group(id), -- registrar group id
    member_from date NOT NULL, --  registrar membership in the group from this date
    member_until date --  registrar membership in the group until this date or unspecified
);

CREATE OR REPLACE FUNCTION registrar_group_map_check() RETURNS "trigger" AS $$
DECLARE
    last_reg_map RECORD;
BEGIN
    IF NEW.member_until IS NOT NULL AND NEW.member_from > NEW.member_until THEN
        RAISE EXCEPTION 'Invalid registrar membership life: member_from > member_until';
    END IF;

    IF TG_OP = 'INSERT' THEN
        SELECT * INTO last_reg_map
           FROM registrar_group_map 
          WHERE registrar_id = NEW.registrar_id
            AND registrar_group_id = NEW.registrar_group_id
            AND id < NEW.id
          ORDER BY member_from DESC, id DESC 
          LIMIT 1;
        IF FOUND THEN
            IF last_reg_map.member_until IS NULL THEN
                UPDATE registrar_group_map 
                   SET member_until = NEW.member_from
                  WHERE id = last_reg_map.id;
                last_reg_map.member_until := NEW.member_from;
            END IF;
            IF last_reg_map.member_until > NEW.member_from  THEN
                RAISE EXCEPTION 'Invalid registrar membership life: last member_until > new member_from';
            END IF;
        END IF;

    ELSEIF TG_OP = 'UPDATE' THEN
        IF NEW.member_from <> OLD.member_from THEN
            RAISE EXCEPTION 'Change of member_from not allowed';
        END IF;
        
        IF NEW.member_until IS NULL AND OLD.member_until IS NOT NULL THEN
            RAISE EXCEPTION 'Change of member_until not allowed';
        END IF;
        
        IF NEW.member_until IS NOT NULL AND OLD.member_until IS NOT NULL 
            AND NEW.member_until <> OLD.member_until THEN
            RAISE EXCEPTION 'Change of member_until not allowed';
        END IF;
        
        IF NEW.registrar_group_id <> OLD.registrar_group_id THEN
            RAISE EXCEPTION 'Change of registrar_group not allowed';
        END IF;
        
        IF NEW.registrar_id <> OLD.registrar_id THEN
            RAISE EXCEPTION 'Change of registrar not allowed';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION registrar_group_map_check()
	IS 'check whether registrar membership change is valid'; 

CREATE TRIGGER "trigger_registrar_group_map"
  AFTER INSERT OR UPDATE ON registrar_group_map
  FOR EACH ROW EXECUTE PROCEDURE registrar_group_map_check();


CREATE INDEX registrar_group_map_member_from_idx ON registrar_group_map(member_from);
CREATE INDEX registrar_group_map_member_until_idx ON registrar_group_map(member_until);

COMMENT ON TABLE registrar_group_map IS 'membership of registar in group';
COMMENT ON COLUMN registrar_group_map.id IS 'registrar group membership id';
COMMENT ON COLUMN registrar_group_map.registrar_id IS 'registrar id';
COMMENT ON COLUMN registrar_group_map.registrar_group_id IS 'group id';
COMMENT ON COLUMN registrar_group_map.member_from 
	IS 'registrar membership in the group from this date';
COMMENT ON COLUMN registrar_group_map.member_until 
	IS 'registrar membership in the group until this date or unspecified';



---
--- notify letters - changes need for postservice
---
ALTER TABLE zone ADD COLUMN warning_letter BOOLEAN NOT NULL DEFAULT TRUE;

CREATE TABLE enum_send_status (
    id INTEGER PRIMARY KEY,
    description TEXT
);

COMMENT ON TABLE enum_send_status IS 'list of statuses when sending a general message to a contact';

-- letters sent electronically as PDF documents to postal service,
-- address is included in the document
CREATE TABLE letter_archive (
  id SERIAL PRIMARY KEY,
  -- initial (default) status is 'file generated & ready for processing'
  status INTEGER NOT NULL DEFAULT 1 REFERENCES enum_send_status(id),
  -- file with pdf about notification (null for old)
  file_id INTEGER REFERENCES files (id),
  crdate timestamp NOT NULL DEFAULT now(),  -- date of insertion in table
  moddate timestamp,    -- date of sending (even if unsuccesfull), it is the time when the send attempt finished
  attempt smallint NOT NULL DEFAULT 0, -- failed attempts to send data
  -- for postservis - bundling letters into batches
  batch_id VARCHAR(64)
);

CREATE INDEX letter_archive_status_idx ON letter_archive (status);
CREATE INDEX letter_archive_batch_id ON letter_archive (batch_id);

COMMENT ON TABLE letter_archive IS 'letters sent electronically as PDF documents to postal service, address is included in the document';
COMMENT ON COLUMN letter_archive.status IS 'initial (default) status is ''file generated & ready for processing'' ';
COMMENT ON COLUMN letter_archive.file_id IS 'file with pdf about notification (null for old)';
COMMENT ON COLUMN letter_archive.crdate IS 'date of insertion in table';
COMMENT ON COLUMN letter_archive.moddate IS 'date of sending (even if unsuccesfull), it is the time when the send attempt finished';
COMMENT ON COLUMN letter_archive.attempt IS 'failed attempts to send data';
COMMENT ON COLUMN letter_archive.batch_id IS 'postservis batch id - multiple letters are bundled into batches';

ALTER TABLE notify_letters ADD COLUMN letter_id INTEGER;
ALTER TABLE notify_letters ADD FOREIGN KEY (letter_id) REFERENCES letter_archive(id);

-- cannot do this before upgrade script take place
-- TODO: make post-upgrade clean script
-- ALTER TABLE notify_letters DROP COLUMN file_id;

COMMENT ON COLUMN notify_letters.letter_id IS 'which message notifies the state change';


---
--- this tables are not used anymore
---
DROP TABLE auth_info_requests;
DROP TABLE object_status_notifications_mail_map;
DROP TABLE object_status_notifications;
DROP TABLE enum_notify;
DROP TABLE bank_ebanka_list;
DROP TABLE bank_statement_item;
DROP TABLE bank_statement_head;


---
--- set owner to fred user for new tables
---
ALTER TABLE registrar_certification OWNER TO fred;
ALTER TABLE registrar_group OWNER TO fred;
ALTER TABLE registrar_group_map OWNER TO fred;
ALTER TABLE letter_archive OWNER TO fred;
ALTER TABLE enum_send_status OWNER TO fred;
