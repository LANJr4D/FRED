---
---
--- THIS SCRIPT MUST BE RUN WITH SUPERUSER PRIVILEGES
--- SO THAT `COPY' CAN WORK
---

BEGIN;
---
--- backup of old tables - these won't be part of replication
---

CREATE TABLE old_invoice AS SELECT * FROM invoice;
ALTER TABLE invoice_object_registry_price_map DROP CONSTRAINT invoice_object_registry_price_map_invoiceid_fkey;
ALTER TABLE invoice_object_registry DROP CONSTRAINT invoice_object_registry_invoiceid_fkey;
ALTER TABLE invoice_mails DROP CONSTRAINT invoice_mails_invoiceid_fkey;
ALTER TABLE invoice_generation DROP CONSTRAINT invoice_generation_invoiceid_fkey;
ALTER TABLE invoice_credit_payment_map DROP CONSTRAINT invoice_credit_payment_map_invoiceid_fkey;
ALTER TABLE invoice_credit_payment_map DROP CONSTRAINT invoice_credit_payment_map_ainvoiceid_fkey;
ALTER TABLE bank_payment DROP CONSTRAINT bank_payment_invoice_id_fkey;
DROP TABLE invoice;

CREATE TABLE old_invoice_prefix AS SELECT * FROM invoice_prefix;
DROP TABLE invoice_prefix;

CREATE TABLE old_price_list AS SELECT * FROM price_list;
DROP TABLE price_list;

CREATE TABLE old_invoice_credit_payment_map AS SELECT * FROM invoice_credit_payment_map;
DROP TABLE invoice_credit_payment_map;

CREATE TABLE old_invoice_generation AS SELECT * FROM invoice_generation;
ALTER TABLE invoice_mails DROP CONSTRAINT invoice_mails_genid_fkey;
DROP TABLE invoice_generation;

CREATE TABLE old_invoice_object_registry AS SELECT * FROM invoice_object_registry;
ALTER TABLE invoice_object_registry_price_map DROP CONSTRAINT invoice_object_registry_price_map_id_fkey;
DROP TABLE invoice_object_registry;

CREATE TABLE old_invoice_object_registry_price_map AS SELECT * FROM invoice_object_registry_price_map;
DROP TABLE invoice_object_registry_price_map;

---
--- TABLE PRICE_LIST
---
CREATE TABLE price_list
(
    id serial PRIMARY KEY, -- primary key
    zone_id integer not null  REFERENCES  zone, -- link to zone, for which is price list valid if it is domain (if it isn't domain then it is NULL)
    operation_id integer NOT NULL REFERENCES enum_operation, -- for which action is a price connected
    valid_from timestamp NOT NULL, -- from when is record valid
    valid_to timestamp default NULL, -- till when is record valid, if it is NULL, it isn't limited
    price numeric(10,2) NOT NULL default 0, -- cost of operation ( for year 12 months )
    quantity integer default 12, -- if it isn't periodic operation NULL
    enable_postpaid_operation boolean DEFAULT 'false'
);

ALTER TABLE price_list OWNER TO fred;

COMMENT ON TABLE price_list IS 'list of operation prices';
COMMENT ON COLUMN price_list.id IS 'unique automatically generated identifier';
COMMENT ON COLUMN price_list.zone_id IS 'link to zone, for which is price list valid if it is domain (if it is not domain then it is NULL)';
COMMENT ON COLUMN price_list.operation_id IS 'for which action is price connected';
COMMENT ON COLUMN price_list.valid_from IS 'from when is record valid';
COMMENT ON COLUMN price_list.valid_to IS 'till when is record valid, if it is NULL then valid is unlimited';
COMMENT ON COLUMN price_list.price IS 'cost of operation (for one year-12 months)';
COMMENT ON COLUMN price_list.quantity IS 'quantity of operation or period (in years) of operation';
COMMENT ON COLUMN price_list.enable_postpaid_operation IS 'true if operation of this specific type can be executed when credit is not sufficient and create debt';



---
--- TABLE INVOICE_PREFIX
---
CREATE TABLE invoice_prefix
(
    id serial NOT NULL PRIMARY KEY,
    zone_id INTEGER REFERENCES zone (id),
    typ integer default 0, -- invoice type 0 advanced 1 normal
    year numeric NOT NULL, -- for which year
    prefix bigint, -- counter with prefix of number line invoice
    CONSTRAINT invoice_prefix_zone_key UNIQUE (zone_id, typ, year)
);

ALTER TABLE invoice_prefix OWNER TO fred;

COMMENT ON TABLE invoice_prefix IS 'list of invoice prefixes';
COMMENT ON COLUMN invoice_prefix.zone_id IS 'reference to zone';
COMMENT ON COLUMN invoice_prefix.typ IS 'invoice type (0-advanced, 1-normal)';
COMMENT ON COLUMN invoice_prefix.year IS 'for which year';
COMMENT ON COLUMN invoice_prefix.prefix IS 'counter with prefix of number of invoice';



---
--- TABLE INVOICE
---
CREATE TABLE invoice
(
   id serial NOT NULL PRIMARY KEY, -- unique primary key
   zone_id INTEGER REFERENCES zone (id),
   CrDate timestamp NOT NULL DEFAULT now(), -- date and time of invoice creation
   TaxDate date NOT NULL, -- date of taxable fulfilment ( when payment cames by advance FA)
   prefix bigint UNIQUE NOT NULL , -- 9 placed number of invoice from invoice_prefix.prefix counted via TaxDate
   registrar_id INTEGER NOT NULL REFERENCES registrar, -- link to registrar
   balance numeric(10,2) DEFAULT 0.0, -- credit from which is taken till zero if it is NULL it is normal invoice
   operations_price numeric(10,2) DEFAULT 0.0, -- account invoice sum price of operations
   VAT numeric NOT NULL, -- VAT percent used for this invoice)
   total numeric(10,2) NOT NULL  DEFAULT 0.0, -- amount without tax ( for accounting is same as price = total amount without tax);
   totalVAT numeric(10,2)  NOT NULL DEFAULT 0.0, -- tax paid (0 for accounted tax it is paid at advance invoice)
   invoice_prefix_id INTEGER NOT NULL REFERENCES invoice_prefix(ID), --  invoice type  from which year is anf which type is according to prefix
   file INTEGER REFERENCES files,-- link to generated PDF (it can be null till is generated)
   fileXML INTEGER REFERENCES files -- link to generated XML (it can be null till is generated)
);

ALTER TABLE invoice OWNER TO fred;

COMMENT ON TABLE invoice IS 'table of invoices';
COMMENT ON COLUMN invoice.id IS 'unique automatically generated identifier';
COMMENT ON COLUMN invoice.zone_id IS 'reference to zone';
COMMENT ON COLUMN invoice.CrDate IS 'date and time of invoice creation';
COMMENT ON COLUMN invoice.TaxDate IS 'date of taxable fulfilment (when payment cames by advance FA)';
COMMENT ON COLUMN invoice.prefix IS '9 placed number of invoice from invoice_prefix.prefix counted via TaxDate';
COMMENT ON COLUMN invoice.registrar_id IS 'link to registrar';
COMMENT ON COLUMN invoice.balance IS '*advance invoice: balance from which operations are charged *account invoice: amount to be paid (0 in case there is no debt)';
COMMENT ON COLUMN invoice.operations_price IS 'sum of operations without tax';
COMMENT ON COLUMN invoice.VAT IS 'VAT hight from account';
COMMENT ON COLUMN invoice.total IS 'amount without tax';
COMMENT ON COLUMN invoice.totalVAT IS 'tax paid';
COMMENT ON COLUMN invoice.invoice_prefix_id IS 'invoice type - which year and type (accounting/advance)';
COMMENT ON COLUMN invoice.file IS 'link to generated PDF file, it can be NULL till file is generated';
COMMENT ON COLUMN invoice.fileXML IS 'link to generated XML file, it can be NULL till file is generated';



---
--- TABLE REGISTRAR_CREDIT
---
CREATE TABLE registrar_credit
(
    id BIGSERIAL PRIMARY KEY,
    credit numeric(30,2) NOT NULL DEFAULT 0,
    registrar_id bigint NOT NULL REFERENCES registrar(id),
    zone_id bigint NOT NULL REFERENCES zone(id),
    CONSTRAINT registrar_credit_unique_key UNIQUE (registrar_id, zone_id)
);

ALTER TABLE registrar_credit OWNER TO fred;

COMMENT ON TABLE registrar_credit IS 'current credit by registrar and zone';



---
--- TABLE REGISTRAR_CREDIT_TRANSACTION
---
CREATE TABLE registrar_credit_transaction
(
    id bigserial PRIMARY KEY,
    balance_change numeric(10,2) NOT NULL,
    registrar_credit_id bigint NOT NULL REFERENCES registrar_credit(id)
);

ALTER TABLE registrar_credit_transaction OWNER TO fred;

COMMENT ON TABLE registrar_credit_transaction IS 'balance changes';



---
--- TABLE INVOICE_OPERATION
---
CREATE TABLE invoice_operation
(
    id serial NOT NULL PRIMARY KEY, -- unique primary key
    ac_invoice_id INTEGER REFERENCES invoice (id) , -- id of invoice for which is item counted
    CrDate timestamp NOT NULL DEFAULT now(),  -- billing date and time
    object_id integer  REFERENCES object_registry (id),
    zone_id INTEGER REFERENCES zone (id),
    registrar_id INTEGER NOT NULL REFERENCES registrar, -- link to registrar
    operation_id INTEGER NOT NULL REFERENCES enum_operation, -- operation type of registration or renew
    date_from date,
    date_to date default NULL,  -- final ExDate only for RENEW
    quantity integer default 0, -- number of unit for renew in months
    registrar_credit_transaction_id bigint UNIQUE NOT NULL REFERENCES registrar_credit_transaction(id)
);

ALTER TABLE invoice_operation OWNER TO fred;

COMMENT ON COLUMN invoice_operation.id IS 'unique automatically generated identifier';
COMMENT ON COLUMN invoice_operation.ac_invoice_id IS 'id of invoice for which is item counted';
COMMENT ON COLUMN invoice_operation.CrDate IS 'billing date and time';
COMMENT ON COLUMN invoice_operation.zone_id IS 'link to zone';
COMMENT ON COLUMN invoice_operation.registrar_id IS 'link to registrar';
COMMENT ON COLUMN invoice_operation.operation_id IS 'operation type of registration or renew';
COMMENT ON COLUMN invoice_operation.date_to IS 'expiration date only for RENEW';
COMMENT ON COLUMN invoice_operation.quantity IS 'number of operations or number of months for renew';

CREATE INDEX invoice_operation_object_id_idx ON invoice_operation (object_id);



---
--- TABLE INVOICE_OPERATION_CHARGE_MAP
---
CREATE TABLE invoice_operation_charge_map
(
    invoice_operation_id INTEGER REFERENCES invoice_operation(ID),
    invoice_id INTEGER REFERENCES invoice (id), -- id of advanced invoice
    price numeric(10,2) NOT NULL default 0 , -- cost for operation
    PRIMARY KEY ( invoice_operation_id ,  invoice_id ) -- unique key
);

ALTER TABLE invoice_operation_charge_map OWNER TO fred;

COMMENT ON COLUMN invoice_operation_charge_map.invoice_id IS 'id of advanced invoice';
COMMENT ON COLUMN invoice_operation_charge_map.price IS 'operation cost';

CREATE INDEX invoice_operation_charge_map_invoice_id_idx ON invoice_operation_charge_map (invoice_id);



---
--- TABLE INVOICE_CREDIT_PAYMENT_MAP
---
CREATE TABLE invoice_credit_payment_map
(
    ac_invoice_id INTEGER REFERENCES invoice (id), -- id of normal invoice
    ad_invoice_id INTEGER REFERENCES invoice (id), -- id of advance invoice
    credit numeric(10,2)  NOT NULL DEFAULT 0.0, -- seized credit
    balance numeric(10,2)  NOT NULL DEFAULT 0.0, -- actual tax balance advance invoice
    PRIMARY KEY (ac_invoice_id, ad_invoice_id)
);

ALTER TABLE invoice_credit_payment_map OWNER TO fred;

COMMENT ON COLUMN invoice_credit_payment_map.ac_invoice_id IS 'id of normal invoice';
COMMENT ON COLUMN invoice_credit_payment_map.ad_invoice_id IS 'id of advance invoice';
COMMENT ON COLUMN invoice_credit_payment_map.credit IS 'seized credit';
COMMENT ON COLUMN invoice_credit_payment_map.balance IS 'actual tax balance advance invoice';

CREATE INDEX invoice_credit_payment_map_ac_invoice_id_idx ON invoice_credit_payment_map (ac_invoice_id);
CREATE INDEX invoice_credit_payment_map_ad_invoice_id_idx ON invoice_credit_payment_map (ad_invoice_id);



---
--- TABLE INVOICE_GENERATION
---
CREATE TABLE invoice_generation
(
    id serial NOT NULL PRIMARY KEY, -- unique primary key
    FromDate date NOT  NULL, -- local date account period from is taken 00:00:00 
    ToDate date NOT NULL, -- 23:59:59 is taken into date
    registrar_id INTEGER NOT NULL REFERENCES registrar, -- link to registrar
    zone_id INTEGER REFERENCES Zone (id),
    invoice_id INTEGER REFERENCES invoice (id) -- id of normal invoice
);

ALTER TABLE invoice_generation OWNER TO fred;

COMMENT ON COLUMN invoice_generation.id IS 'unique automatically generated identifier';
COMMENT ON COLUMN invoice_generation.invoice_id IS 'id of normal invoice';



---
--- TABLE REGISTRARINVOICE
---
ALTER TABLE registrarinvoice DROP COLUMN lastdate;



---
--- procedure for safe registrar credit change (disabled update and delete for
--- registrar_credit_transaction table
---
CREATE OR REPLACE FUNCTION registrar_credit_change_lock()
RETURNS "trigger" AS $$
DECLARE
    registrar_credit_result RECORD;
BEGIN
    IF TG_OP = 'INSERT' THEN
        SELECT id, credit FROM registrar_credit INTO registrar_credit_result
            WHERE id = NEW.registrar_credit_id FOR UPDATE;
        IF FOUND THEN
            UPDATE registrar_credit
                SET credit = credit + NEW.balance_change
                WHERE id = registrar_credit_result.id;
        ELSE
            RAISE EXCEPTION 'Invalid registrar_credit_id';
        END IF;
    ELSE
        RAISE EXCEPTION 'Unallowed operation to registrar_credit_transaction';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION registrar_credit_change_lock() OWNER TO fred;

COMMENT ON FUNCTION registrar_credit_change_lock()
        IS 'check and lock insert into registrar_credit_transaction disable update and delete';



---
--- TABLE BANK_PAYMENT_REGISTRAR_CREDIT_TRANSACTION_MAP
---
CREATE TABLE bank_payment_registrar_credit_transaction_map
(
    id BIGSERIAL PRIMARY KEY,
    bank_payment_id bigint NOT NULL REFERENCES bank_payment(id),
    registrar_credit_transaction_id bigint UNIQUE NOT NULL REFERENCES registrar_credit_transaction(id)
);

ALTER TABLE bank_payment_registrar_credit_transaction_map OWNER TO fred;

COMMENT ON TABLE bank_payment_registrar_credit_transaction_map
        IS 'payment assigned to credit items';



---
--- TABLE INVOICE_REGISTRAR_CREDIT_TRANSACTION_MAP
---
CREATE TABLE invoice_registrar_credit_transaction_map
(
    id BIGSERIAL PRIMARY KEY,
    invoice_id bigint NOT NULL REFERENCES invoice(id),
    registrar_credit_transaction_id bigint UNIQUE NOT NULL REFERENCES registrar_credit_transaction(id)
);

ALTER TABLE invoice_registrar_credit_transaction_map OWNER TO fred;

COMMENT ON TABLE invoice_registrar_credit_transaction_map 
        IS 'positive credit item from payment assigned to deposit or account invoice';



---
--- TABLE REGISTRAR_DISCONNECT
---
CREATE TABLE registrar_disconnect
(
    id SERIAL PRIMARY KEY,
    registrarid INTEGER NOT NULL REFERENCES registrar(id),
    blocked_from TIMESTAMP NOT NULL DEFAULT now(),
    blocked_to TIMESTAMP,
    unblock_request_id BIGINT
);

ALTER TABLE registrar_disconnect OWNER TO fred;

COMMENT ON TABLE registrar_disconnect IS 'registrars with blocked access to registry';


---
--- TABLE REQUEST_FEE_REGISTRAR_PARAMETER
---
CREATE TABLE request_fee_registrar_parameter
(
    registrar_id INTEGER PRIMARY KEY REFERENCES registrar(id),
    request_price_limit numeric(10, 2) NOT NULL,
    email varchar(200) NOT NULL,
    telephone varchar(64) NOT NULL
);

ALTER TABLE request_fee_registrar_parameter OWNER TO fred;

COMMENT ON TABLE request_fee_registrar_parameter IS 'parameters for request fee module';
COMMENT ON COLUMN request_fee_registrar_parameter.request_price_limit IS 'limit for requests price (when reached, registrar is blocked)';



---
--- TABLE REQUEST_FEE_PARAMETER
---
ALTER TABLE request_fee_parameter ADD COLUMN zone_id INTEGER REFERENCES zone(id);

---
--- drop foreign keys 
---

ALTER TABLE invoice_operation DROP CONSTRAINT
 invoice_operation_ac_invoice_id_fkey;
ALTER TABLE invoice_operation DROP CONSTRAINT
 invoice_operation_object_id_fkey;
ALTER TABLE invoice_operation DROP CONSTRAINT
 invoice_operation_operation_id_fkey;
ALTER TABLE invoice_operation DROP CONSTRAINT
 invoice_operation_registrar_credit_transaction_id_fkey;
ALTER TABLE invoice_operation DROP CONSTRAINT
 invoice_operation_registrar_id_fkey;
ALTER TABLE invoice_operation DROP CONSTRAINT
 invoice_operation_zone_id_fkey;

ALTER TABLE invoice_operation_charge_map DROP CONSTRAINT
 invoice_operation_charge_map_invoice_id_fkey;

ALTER TABLE invoice_operation_charge_map DROP CONSTRAINT
 invoice_operation_charge_map_invoice_operation_id_fkey;

COMMIT;
