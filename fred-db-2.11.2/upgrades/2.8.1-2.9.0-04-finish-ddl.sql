
BEGIN;

---
--- return foreign keys back
---

ALTER TABLE invoice_operation ADD CONSTRAINT
 invoice_operation_ac_invoice_id_fkey FOREIGN KEY
 (ac_invoice_id) REFERENCES invoice (id);

ALTER TABLE invoice_operation ADD CONSTRAINT
 invoice_operation_object_id_fkey FOREIGN KEY
 (object_id) REFERENCES object_registry (id);

ALTER TABLE invoice_operation ADD CONSTRAINT
 invoice_operation_operation_id_fkey FOREIGN KEY
 (operation_id) REFERENCES enum_operation (id);

ALTER TABLE invoice_operation ADD CONSTRAINT
 invoice_operation_registrar_credit_transaction_id_fkey FOREIGN KEY
 (registrar_credit_transaction_id) REFERENCES registrar_credit_transaction(id);

ALTER TABLE invoice_operation ADD CONSTRAINT
 invoice_operation_registrar_id_fkey FOREIGN KEY
 (registrar_id) REFERENCES registrar (id);

ALTER TABLE invoice_operation ADD CONSTRAINT
 invoice_operation_zone_id_fkey FOREIGN KEY
 (zone_id) REFERENCES zone (id);

ALTER TABLE invoice_operation_charge_map ADD CONSTRAINT
 invoice_operation_charge_map_invoice_id_fkey FOREIGN KEY
 (invoice_id) REFERENCES invoice (id);

ALTER TABLE invoice_operation_charge_map ADD CONSTRAINT
 invoice_operation_charge_map_invoice_operation_id_fkey FOREIGN KEY
 (invoice_operation_id) REFERENCES invoice_operation(id);


ALTER TABLE invoice_mails ADD CONSTRAINT invoice_mails_genid_fkey 
    FOREIGN KEY (genid) REFERENCES invoice_generation (id);
ALTER TABLE invoice_mails ADD CONSTRAINT invoice_mails_invoiceid_fkey
    FOREIGN KEY (invoiceid) REFERENCES invoice (id);


--- 
---  Ticket #5808
---
ALTER TABLE request_fee_parameter ALTER COLUMN zone_id SET NOT NULL;


--- create trigger
CREATE TRIGGER "trigger_registrar_credit_transaction"
  AFTER INSERT OR UPDATE OR DELETE ON registrar_credit_transaction
  FOR EACH ROW EXECUTE PROCEDURE registrar_credit_change_lock();


COMMIT;

