---
--- Ticket #5796
---
--- THIS SCRIPT MUST BE RUN WITH SUPERUSER PRIVILEGES
--- SO THAT `COPY' CAN WORK
---

--drop table registrar_credit_transaction cascade;
--drop table registrar_credit cascade;

--drop table bank_payment_registrar_credit_transaction_map cascade;
--drop table invoice_registrar_credit_transaction_map;


--#!sql

BEGIN;

----- backup old version of invoice_object_registry

COPY invoice TO '/var/tmp/temp_upgrade_invoice.csv';
COPY invoice_prefix TO '/var/tmp/temp_upgrade_invoice_prefix.csv';
COPY price_list TO '/var/tmp/temp_upgrade_price_list.csv';
COPY invoice_credit_payment_map TO '/var/tmp/temp_upgrade_invoice_credit_payment_map.csv';
COPY invoice_generation TO '/var/tmp/temp_upgrade_invoice_generation.csv';

COPY invoice_object_registry TO '/var/tmp/temp_upgrade_invoice_object_registry.csv';
COPY invoice_object_registry_price_map TO '/var/tmp/temp_upgrade_invoice_object_registry_price_map.csv';

--- last usage of bank_payment.invoice_id , bank_bayment will have removed invoice_id
COPY 
    (SELECT bp.id, bp.invoice_id  
    FROM bank_payment bp)
TO '/var/tmp/temp_upgrade_bank_payment.csv';

COMMIT;

