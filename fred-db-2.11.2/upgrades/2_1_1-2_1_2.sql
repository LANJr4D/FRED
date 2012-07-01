ALTER TABLE history 
    ADD COLUMN valid_from TIMESTAMP NOT NULL DEFAULT NOW(),
    ADD COLUMN valid_to TIMESTAMP,
    ADD COLUMN next INTEGER;

COMMENT ON COLUMN history.valid_from IS 'date from which was this history created';
COMMENT ON COLUMN history.valid_to IS 'date to which was history actual (NULL if it still is)';
COMMENT ON COLUMN history.next IS 'next history id';

CREATE INDEX history_valid_from_idx ON history (valid_from);
CREATE INDEX history_valid_to_idx ON history (valid_to);
CREATE UNIQUE INDEX history_next_idx ON history (next);
    
-- takes about 15 minutes:
SELECT h.id AS historyid, a.enddate AS date 
INTO TEMPORARY TABLE tmp_history_dates 
FROM history h join action a on (h.action=a.id)
WHERE a.enddate IS NOT NULL;

-- creates tmp table with versions number of histories of each object   
SELECT o1.historyid, o1.id, count(*) AS version 
INTO TEMPORARY TABLE tmp_history_versions 
FROM object_history o1 
JOIN object_history o2 
   ON (o2.id=o1.id and o1.historyid>=o2.historyid) 
GROUP BY o1.historyid, o1.id;


SELECT d1.historyid, d1.date AS valid_from, d2.date AS valid_to, hv1.version AS version, hv1.id as objectid 
INTO TEMPORARY TABLE tmp_history_times 
FROM tmp_history_dates d1 
JOIN tmp_history_versions hv1 
  ON (d1.historyid=hv1.historyid) 
LEFT JOIN tmp_history_versions hv2 
  ON (hv1.id=hv2.id AND hv1.version+1=hv2.version) 
LEFT JOIN tmp_history_dates d2 
  ON (d2.historyid=hv2.historyid);

-- fills history valid_from and valid_to from tmp_history_times
UPDATE history H
SET valid_from = THT.valid_from, valid_to = THT.valid_to, next = THT_NEXT.historyid
FROM
    tmp_history_times THT
    LEFT OUTER JOIN tmp_history_times THT_NEXT ON (THT_NEXT.objectid = THT.objectid AND THT_NEXT.version = THT.version + 1)
WHERE THT.historyid = H.id;

-- fills history valid_to from object_registry.erdate (only last history of object).
-- this is becouse we want valid_to of the last history of the object to be set to erdate
UPDATE history H
SET valid_to = OBR.erdate 
FROM object_registry OBR
WHERE H.id = OBR.historyid;


-- For updating previous history record (or current in case of deletion of object)
CREATE OR REPLACE FUNCTION object_registry_update_history_rec() RETURNS TRIGGER AS $$
BEGIN
    -- when updation object, set valid_to and next of previous history record
    IF OLD.historyid != NEW.historyid THEN
        UPDATE history
            SET valid_to = NOW(), -- NOW() is the same during the transaction, so this will be the same as valid_from of new history record
                next = NEW.historyid
            WHERE id = OLD.historyid;
    END IF; 
    
    -- when deleting object (setting object_registry.erdate), set valid_to of current history record    
    IF OLD.erdate IS NULL and NEW.erdate IS NOT NULL THEN
        UPDATE history
            SET valid_to = NEW.erdate
            WHERE id = OLD.historyid;
    END IF; 
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--DROP TRIGGER trigger_object_registry_update_history_rec ON object_registry;
CREATE TRIGGER trigger_object_registry_update_history_rec AFTER UPDATE
    ON object_registry FOR EACH ROW
    EXECUTE PROCEDURE object_registry_update_history_rec();

