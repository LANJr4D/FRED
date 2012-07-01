
---
--- #4365
---
---

ALTER TABLE public_request ADD COLUMN logd_request_id INTEGER;

---
--- Ticket #4578
---
CREATE TABLE public_request_auth (
      id integer PRIMARY KEY NOT NULL REFERENCES public_request(id),
      identification varchar(32) NOT NULL UNIQUE,
      password varchar(64) NOT NULL
);

---
--- Ticket #4639
---
CREATE TABLE public_request_messages_map
(
  id serial PRIMARY KEY NOT NULL,
  public_request_id INTEGER REFERENCES public_request (id),
  message_archive_id INTEGER, -- REFERENCES message_archive (id), 
  mail_archive_id INTEGER, -- REFERENCES mail_archive (id),
  UNIQUE (public_request_id, message_archive_id),
  UNIQUE (public_request_id, mail_archive_id)
);
---
--- Ticket #4291
---

ALTER TABLE registrar ALTER COLUMN ico TYPE VARCHAR(50);
ALTER TABLE registrar ALTER COLUMN dic TYPE VARCHAR(50);

---
--- Ticket #4508 - logger request_id for history records
---

ALTER TABLE history ADD COLUMN request_id integer;

---
--- messages
---

CREATE TABLE message_status
(
  id  SERIAL PRIMARY KEY,
  status_name VARCHAR(64) -- ready, being_sent, sent, send_failed
);

comment on table message_status is 'named message states';

CREATE TABLE comm_type
(
  id  SERIAL PRIMARY KEY,
  type VARCHAR(64) -- email, letter, sms
);

comment on table comm_type is 'type of communication with contact';


CREATE TABLE message_type
(
  id  SERIAL PRIMARY KEY,
  type VARCHAR(64) -- domain_expiration, mojeid_pin2, mojeid_pin3,...
);

comment on table message_type is 'type of message with respect to subject of message';

CREATE TABLE message_archive
(
  id  SERIAL PRIMARY KEY,
  crdate timestamp without time zone NOT NULL DEFAULT now(), -- date of insertion in table
  moddate timestamp without time zone, -- date of sending (even if unsuccesfull)
  attempt smallint NOT NULL DEFAULT 0, -- failed attempts to send data
  status_id INTEGER REFERENCES message_status (id), -- message_status
  comm_type_id INTEGER REFERENCES comm_type (id), --  communication channel
  message_type_id INTEGER REFERENCES message_type (id) --  message type
);

CREATE INDEX message_archive_crdate_idx ON message_archive (crdate);
CREATE INDEX message_archive_status_id_idx ON message_archive (status_id);
CREATE INDEX message_archive_comm_type_id_idx ON message_archive (comm_type_id);

comment on column message_archive.crdate is 'date and time of insertion in table';
comment on column message_archive.moddate is 'date and time of sending (event unsuccesfull)';
comment on column message_archive.status_id is 'status';

CREATE TABLE message_contact_history_map
(
  id  SERIAL PRIMARY KEY,
  contact_object_registry_id INTEGER,-- REFERENCES object_registry (id), -- id type contact
  contact_history_historyid INTEGER, -- REFERENCES contact_history (historyid), -- historyid 
  message_archive_id INTEGER REFERENCES message_archive (id) -- message
);

--sms archive
CREATE TABLE sms_archive
(
  id INTEGER PRIMARY KEY REFERENCES message_archive (id), -- message_archive id
  phone_number VARCHAR(64) NOT NULL, -- copy of phone number
  phone_number_id INTEGER, -- unused 
  content TEXT -- sms text content
);

INSERT INTO message_archive (id, status_id, crdate, moddate, attempt, comm_type_id) SELECT id, status, crdate, moddate, attempt 
, (SELECT id FROM comm_type WHERE type='letter') as comm_type
FROM letter_archive;

--sequence update
select setval('message_archive_id_seq',(select max(id) from message_archive));


ALTER TABLE letter_archive ADD CONSTRAINT letter_archive_id_fkey FOREIGN KEY (id) REFERENCES message_archive(id);

ALTER TABLE letter_archive ADD COLUMN postal_address_name VARCHAR(1024);
ALTER TABLE letter_archive ADD COLUMN postal_address_organization VARCHAR(1024);
ALTER TABLE letter_archive ADD COLUMN postal_address_street1 VARCHAR(1024);
ALTER TABLE letter_archive ADD COLUMN postal_address_street2 VARCHAR(1024);
ALTER TABLE letter_archive ADD COLUMN postal_address_street3 VARCHAR(1024);
ALTER TABLE letter_archive ADD COLUMN postal_address_city VARCHAR(1024);
ALTER TABLE letter_archive ADD COLUMN postal_address_stateorprovince VARCHAR(1024);
ALTER TABLE letter_archive ADD COLUMN postal_address_postalcode VARCHAR(32);
ALTER TABLE letter_archive ADD COLUMN postal_address_country VARCHAR(1024);

ALTER TABLE letter_archive ADD COLUMN  postal_address_id INTEGER; --unused

ALTER TABLE letter_archive DROP COLUMN status;
ALTER TABLE letter_archive DROP COLUMN crdate;
ALTER TABLE letter_archive DROP COLUMN moddate;
ALTER TABLE letter_archive DROP COLUMN attempt;

ALTER TABLE letter_archive ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE letter_archive_id_seq;
