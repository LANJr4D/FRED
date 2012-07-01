---
--- Ticket #6298
---
ALTER TABLE invoice_prefix
    ADD CONSTRAINT invoice_prefix_invoice_typ_fkey FOREIGN KEY (typ) REFERENCES invoice_type (id);

