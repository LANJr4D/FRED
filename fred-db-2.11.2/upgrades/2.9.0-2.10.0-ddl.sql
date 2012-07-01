---
--- Ticket #6655
---
CREATE SEQUENCE epp_login_id_seq;


---
--- fixing history table
---
ALTER TABLE history
    ALTER COLUMN action DROP NOT NULL;

