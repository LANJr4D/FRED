---
--- dont forget to update database schema version
---
UPDATE enum_parameters SET val = '2.2.0' WHERE id = 1;


---
--- Ticket #1873 - remove public_request - action table relationship
---

ALTER TABLE public_request ADD COLUMN registrar_id INTEGER;
ALTER TABLE public_request ADD FOREIGN KEY (registrar_id) REFERENCES registrar(id);

--- fill in values for current data (TEST THIS)
BEGIN;
LOCK TABLE public_request IN ACCESS EXCLUSIVE MODE;

UPDATE
    public_request pr
SET
    registrar_id = (SELECT
                        l.registrarid
                    FROM
                        action a
                        JOIN login l ON (a.clientid = l.id)
                    WHERE
                        a.id = pr.epp_action_id);
END;

---
--- Ticket #2149 - add flag to enum domain for whether is valid to publish in
--- enum dictionary or not
---
ALTER TABLE enumval ADD COLUMN publish BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE enumval_history ADD COLUMN publish BOOLEAN NOT NULL DEFAULT false;

