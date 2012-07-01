---
--- Ticket #6462
---
ALTER TABLE bank_payment
    ALTER COLUMN account_number TYPE text;


---
--- Ticket #6298
---
CREATE TABLE invoice_type
(
    id serial NOT NULL PRIMARY KEY,
    name text
);

COMMENT ON TABLE invoice_type IS
    'invoice types list';

CREATE TABLE invoice_number_prefix
(
    id serial NOT NULL PRIMARY KEY,
    prefix integer NOT NULL,
    zone_id bigint NOT NULL REFERENCES zone(id),
    invoice_type_id bigint NOT NULL REFERENCES invoice_type (id),
    CONSTRAINT invoice_number_prefix_unique_key UNIQUE (zone_id, invoice_type_id)
);

COMMENT ON TABLE invoice_number_prefix IS
    'prefixes to invoice number, next year prefixes are generated according to records in this table';
COMMENT ON COLUMN invoice_number_prefix.prefix IS 'two-digit number';


---
--- Ticket #6772
---
ALTER TABLE epp_info_buffer_content
    DROP CONSTRAINT epp_info_buffer_content_object_id_fkey;

