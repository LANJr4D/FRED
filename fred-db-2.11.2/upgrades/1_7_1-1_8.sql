-- system operational parametr
-- parameters are accessed through their id not name, so proper
-- numbering is essential

CREATE TABLE enum_parameters (
  id INTEGER PRIMARY KEY, -- primary identification 
  name VARCHAR(100) NOT NULL UNIQUE, -- descriptive name (informational)
  val VARCHAR(100) NOT NULL -- value of parameter
);

-- parametr 1 is for checking data model version and for applying upgrade
-- scripts
INSERT INTO enum_parameters (id, name, val) 
VALUES (1, 'model_version', '1.8');
-- parametr 2 is for updating table enum_tlds by data from url
-- http://data.iana.org/TLD/tlds-alpha-by-domain.txt
INSERT INTO enum_parameters (id, name, val) 
VALUES (2, 'tld_list_version', '2008013001');
-- parametr 3 is used to change state of domain to unguarded and remove
-- this domain from DNS. value is number of dates relative to date 
-- domain.exdate 
INSERT INTO enum_parameters (id, name, val) 
VALUES (3, 'expiration_notify_period', '-30');
-- parametr 4 is used to change state of domain to unguarded and remove
-- this domain from DNS. value is number of dates relative to date 
-- domain.exdate 
INSERT INTO enum_parameters (id, name, val) 
VALUES (4, 'expiration_dns_protection_period', '30');
-- parametr 5 is used to change state of domain to deleteWarning and 
-- generate letter with warning. value number of dates relative to date 
-- domain.exdate 
INSERT INTO enum_parameters (id, name, val) 
VALUES (5, 'expiration_letter_warning_period', '34');
-- parametr 6 is used to change state of domain to deleteCandidate and 
-- unregister domain from system. value is number of dates relative to date 
-- domain.exdate 
INSERT INTO enum_parameters (id, name, val) 
VALUES (6, 'expiration_registration_protection_period', '45');
-- parametr 7 is used to change state of domain to validationWarning1 and 
-- send poll message to registrar. value is number of dates relative to date 
-- domain.exdate 
INSERT INTO enum_parameters (id, name, val) 
VALUES (7, 'validation_notify1_period', '-30');
-- parametr 8 is used to change state of domain to validationWarning2 and 
-- send email to registrant. value is number of dates relative to date 
-- domain.exdate 
INSERT INTO enum_parameters (id, name, val) 
VALUES (8, 'validation_notify2_period', '-15');
-- parametr 9 is used to identify hour when objects are deleted 
-- and domains are moving outzone. value is number of hours relative to date 
-- of operation
INSERT INTO enum_parameters (id, name, val) 
VALUES (9, 'regular_day_procedure_period', '14');
-- parametr 10 is used to identify time zone in which parameter 9 is specified  
INSERT INTO enum_parameters (id, name, val) 
VALUES (10, 'regular_day_procedure_zone', 'CET');

-- list of available tlds for checking of dns host tld
CREATE TABLE enum_tlds (
  tld VARCHAR(64) NOT NULL PRIMARY KEY
);

INSERT INTO enum_tlds (tld) VALUES ('AC');
INSERT INTO enum_tlds (tld) VALUES ('AD');
INSERT INTO enum_tlds (tld) VALUES ('AE');
INSERT INTO enum_tlds (tld) VALUES ('AERO');
INSERT INTO enum_tlds (tld) VALUES ('AF');
INSERT INTO enum_tlds (tld) VALUES ('AG');
INSERT INTO enum_tlds (tld) VALUES ('AI');
INSERT INTO enum_tlds (tld) VALUES ('AL');
INSERT INTO enum_tlds (tld) VALUES ('AM');
INSERT INTO enum_tlds (tld) VALUES ('AN');
INSERT INTO enum_tlds (tld) VALUES ('AO');
INSERT INTO enum_tlds (tld) VALUES ('AQ');
INSERT INTO enum_tlds (tld) VALUES ('AR');
INSERT INTO enum_tlds (tld) VALUES ('ARPA');
INSERT INTO enum_tlds (tld) VALUES ('AS');
INSERT INTO enum_tlds (tld) VALUES ('ASIA');
INSERT INTO enum_tlds (tld) VALUES ('AT');
INSERT INTO enum_tlds (tld) VALUES ('AU');
INSERT INTO enum_tlds (tld) VALUES ('AW');
INSERT INTO enum_tlds (tld) VALUES ('AX');
INSERT INTO enum_tlds (tld) VALUES ('AZ');
INSERT INTO enum_tlds (tld) VALUES ('BA');
INSERT INTO enum_tlds (tld) VALUES ('BB');
INSERT INTO enum_tlds (tld) VALUES ('BD');
INSERT INTO enum_tlds (tld) VALUES ('BE');
INSERT INTO enum_tlds (tld) VALUES ('BF');
INSERT INTO enum_tlds (tld) VALUES ('BG');
INSERT INTO enum_tlds (tld) VALUES ('BH');
INSERT INTO enum_tlds (tld) VALUES ('BI');
INSERT INTO enum_tlds (tld) VALUES ('BIZ');
INSERT INTO enum_tlds (tld) VALUES ('BJ');
INSERT INTO enum_tlds (tld) VALUES ('BM');
INSERT INTO enum_tlds (tld) VALUES ('BN');
INSERT INTO enum_tlds (tld) VALUES ('BO');
INSERT INTO enum_tlds (tld) VALUES ('BR');
INSERT INTO enum_tlds (tld) VALUES ('BS');
INSERT INTO enum_tlds (tld) VALUES ('BT');
INSERT INTO enum_tlds (tld) VALUES ('BV');
INSERT INTO enum_tlds (tld) VALUES ('BW');
INSERT INTO enum_tlds (tld) VALUES ('BY');
INSERT INTO enum_tlds (tld) VALUES ('BZ');
INSERT INTO enum_tlds (tld) VALUES ('CA');
INSERT INTO enum_tlds (tld) VALUES ('CAT');
INSERT INTO enum_tlds (tld) VALUES ('CC');
INSERT INTO enum_tlds (tld) VALUES ('CD');
INSERT INTO enum_tlds (tld) VALUES ('CF');
INSERT INTO enum_tlds (tld) VALUES ('CG');
INSERT INTO enum_tlds (tld) VALUES ('CH');
INSERT INTO enum_tlds (tld) VALUES ('CI');
INSERT INTO enum_tlds (tld) VALUES ('CK');
INSERT INTO enum_tlds (tld) VALUES ('CL');
INSERT INTO enum_tlds (tld) VALUES ('CM');
INSERT INTO enum_tlds (tld) VALUES ('CN');
INSERT INTO enum_tlds (tld) VALUES ('CO');
INSERT INTO enum_tlds (tld) VALUES ('COM');
INSERT INTO enum_tlds (tld) VALUES ('COOP');
INSERT INTO enum_tlds (tld) VALUES ('CR');
INSERT INTO enum_tlds (tld) VALUES ('CU');
INSERT INTO enum_tlds (tld) VALUES ('CV');
INSERT INTO enum_tlds (tld) VALUES ('CX');
INSERT INTO enum_tlds (tld) VALUES ('CY');
INSERT INTO enum_tlds (tld) VALUES ('CZ');
INSERT INTO enum_tlds (tld) VALUES ('DE');
INSERT INTO enum_tlds (tld) VALUES ('DJ');
INSERT INTO enum_tlds (tld) VALUES ('DK');
INSERT INTO enum_tlds (tld) VALUES ('DM');
INSERT INTO enum_tlds (tld) VALUES ('DO');
INSERT INTO enum_tlds (tld) VALUES ('DZ');
INSERT INTO enum_tlds (tld) VALUES ('EC');
INSERT INTO enum_tlds (tld) VALUES ('EDU');
INSERT INTO enum_tlds (tld) VALUES ('EE');
INSERT INTO enum_tlds (tld) VALUES ('EG');
INSERT INTO enum_tlds (tld) VALUES ('ER');
INSERT INTO enum_tlds (tld) VALUES ('ES');
INSERT INTO enum_tlds (tld) VALUES ('ET');
INSERT INTO enum_tlds (tld) VALUES ('EU');
INSERT INTO enum_tlds (tld) VALUES ('FI');
INSERT INTO enum_tlds (tld) VALUES ('FJ');
INSERT INTO enum_tlds (tld) VALUES ('FK');
INSERT INTO enum_tlds (tld) VALUES ('FM');
INSERT INTO enum_tlds (tld) VALUES ('FO');
INSERT INTO enum_tlds (tld) VALUES ('FR');
INSERT INTO enum_tlds (tld) VALUES ('GA');
INSERT INTO enum_tlds (tld) VALUES ('GB');
INSERT INTO enum_tlds (tld) VALUES ('GD');
INSERT INTO enum_tlds (tld) VALUES ('GE');
INSERT INTO enum_tlds (tld) VALUES ('GF');
INSERT INTO enum_tlds (tld) VALUES ('GG');
INSERT INTO enum_tlds (tld) VALUES ('GH');
INSERT INTO enum_tlds (tld) VALUES ('GI');
INSERT INTO enum_tlds (tld) VALUES ('GL');
INSERT INTO enum_tlds (tld) VALUES ('GM');
INSERT INTO enum_tlds (tld) VALUES ('GN');
INSERT INTO enum_tlds (tld) VALUES ('GOV');
INSERT INTO enum_tlds (tld) VALUES ('GP');
INSERT INTO enum_tlds (tld) VALUES ('GQ');
INSERT INTO enum_tlds (tld) VALUES ('GR');
INSERT INTO enum_tlds (tld) VALUES ('GS');
INSERT INTO enum_tlds (tld) VALUES ('GT');
INSERT INTO enum_tlds (tld) VALUES ('GU');
INSERT INTO enum_tlds (tld) VALUES ('GW');
INSERT INTO enum_tlds (tld) VALUES ('GY');
INSERT INTO enum_tlds (tld) VALUES ('HK');
INSERT INTO enum_tlds (tld) VALUES ('HM');
INSERT INTO enum_tlds (tld) VALUES ('HN');
INSERT INTO enum_tlds (tld) VALUES ('HR');
INSERT INTO enum_tlds (tld) VALUES ('HT');
INSERT INTO enum_tlds (tld) VALUES ('HU');
INSERT INTO enum_tlds (tld) VALUES ('ID');
INSERT INTO enum_tlds (tld) VALUES ('IE');
INSERT INTO enum_tlds (tld) VALUES ('IL');
INSERT INTO enum_tlds (tld) VALUES ('IM');
INSERT INTO enum_tlds (tld) VALUES ('IN');
INSERT INTO enum_tlds (tld) VALUES ('INFO');
INSERT INTO enum_tlds (tld) VALUES ('INT');
INSERT INTO enum_tlds (tld) VALUES ('IO');
INSERT INTO enum_tlds (tld) VALUES ('IQ');
INSERT INTO enum_tlds (tld) VALUES ('IR');
INSERT INTO enum_tlds (tld) VALUES ('IS');
INSERT INTO enum_tlds (tld) VALUES ('IT');
INSERT INTO enum_tlds (tld) VALUES ('JE');
INSERT INTO enum_tlds (tld) VALUES ('JM');
INSERT INTO enum_tlds (tld) VALUES ('JO');
INSERT INTO enum_tlds (tld) VALUES ('JOBS');
INSERT INTO enum_tlds (tld) VALUES ('JP');
INSERT INTO enum_tlds (tld) VALUES ('KE');
INSERT INTO enum_tlds (tld) VALUES ('KG');
INSERT INTO enum_tlds (tld) VALUES ('KH');
INSERT INTO enum_tlds (tld) VALUES ('KI');
INSERT INTO enum_tlds (tld) VALUES ('KM');
INSERT INTO enum_tlds (tld) VALUES ('KN');
INSERT INTO enum_tlds (tld) VALUES ('KP');
INSERT INTO enum_tlds (tld) VALUES ('KR');
INSERT INTO enum_tlds (tld) VALUES ('KW');
INSERT INTO enum_tlds (tld) VALUES ('KY');
INSERT INTO enum_tlds (tld) VALUES ('KZ');
INSERT INTO enum_tlds (tld) VALUES ('LA');
INSERT INTO enum_tlds (tld) VALUES ('LB');
INSERT INTO enum_tlds (tld) VALUES ('LC');
INSERT INTO enum_tlds (tld) VALUES ('LI');
INSERT INTO enum_tlds (tld) VALUES ('LK');
INSERT INTO enum_tlds (tld) VALUES ('LR');
INSERT INTO enum_tlds (tld) VALUES ('LS');
INSERT INTO enum_tlds (tld) VALUES ('LT');
INSERT INTO enum_tlds (tld) VALUES ('LU');
INSERT INTO enum_tlds (tld) VALUES ('LV');
INSERT INTO enum_tlds (tld) VALUES ('LY');
INSERT INTO enum_tlds (tld) VALUES ('MA');
INSERT INTO enum_tlds (tld) VALUES ('MC');
INSERT INTO enum_tlds (tld) VALUES ('MD');
INSERT INTO enum_tlds (tld) VALUES ('ME');
INSERT INTO enum_tlds (tld) VALUES ('MG');
INSERT INTO enum_tlds (tld) VALUES ('MH');
INSERT INTO enum_tlds (tld) VALUES ('MIL');
INSERT INTO enum_tlds (tld) VALUES ('MK');
INSERT INTO enum_tlds (tld) VALUES ('ML');
INSERT INTO enum_tlds (tld) VALUES ('MM');
INSERT INTO enum_tlds (tld) VALUES ('MN');
INSERT INTO enum_tlds (tld) VALUES ('MO');
INSERT INTO enum_tlds (tld) VALUES ('MOBI');
INSERT INTO enum_tlds (tld) VALUES ('MP');
INSERT INTO enum_tlds (tld) VALUES ('MQ');
INSERT INTO enum_tlds (tld) VALUES ('MR');
INSERT INTO enum_tlds (tld) VALUES ('MS');
INSERT INTO enum_tlds (tld) VALUES ('MT');
INSERT INTO enum_tlds (tld) VALUES ('MU');
INSERT INTO enum_tlds (tld) VALUES ('MUSEUM');
INSERT INTO enum_tlds (tld) VALUES ('MV');
INSERT INTO enum_tlds (tld) VALUES ('MW');
INSERT INTO enum_tlds (tld) VALUES ('MX');
INSERT INTO enum_tlds (tld) VALUES ('MY');
INSERT INTO enum_tlds (tld) VALUES ('MZ');
INSERT INTO enum_tlds (tld) VALUES ('NA');
INSERT INTO enum_tlds (tld) VALUES ('NAME');
INSERT INTO enum_tlds (tld) VALUES ('NC');
INSERT INTO enum_tlds (tld) VALUES ('NE');
INSERT INTO enum_tlds (tld) VALUES ('NET');
INSERT INTO enum_tlds (tld) VALUES ('NF');
INSERT INTO enum_tlds (tld) VALUES ('NG');
INSERT INTO enum_tlds (tld) VALUES ('NI');
INSERT INTO enum_tlds (tld) VALUES ('NL');
INSERT INTO enum_tlds (tld) VALUES ('NO');
INSERT INTO enum_tlds (tld) VALUES ('NP');
INSERT INTO enum_tlds (tld) VALUES ('NR');
INSERT INTO enum_tlds (tld) VALUES ('NU');
INSERT INTO enum_tlds (tld) VALUES ('NZ');
INSERT INTO enum_tlds (tld) VALUES ('OM');
INSERT INTO enum_tlds (tld) VALUES ('ORG');
INSERT INTO enum_tlds (tld) VALUES ('PA');
INSERT INTO enum_tlds (tld) VALUES ('PE');
INSERT INTO enum_tlds (tld) VALUES ('PF');
INSERT INTO enum_tlds (tld) VALUES ('PG');
INSERT INTO enum_tlds (tld) VALUES ('PH');
INSERT INTO enum_tlds (tld) VALUES ('PK');
INSERT INTO enum_tlds (tld) VALUES ('PL');
INSERT INTO enum_tlds (tld) VALUES ('PM');
INSERT INTO enum_tlds (tld) VALUES ('PN');
INSERT INTO enum_tlds (tld) VALUES ('PR');
INSERT INTO enum_tlds (tld) VALUES ('PRO');
INSERT INTO enum_tlds (tld) VALUES ('PS');
INSERT INTO enum_tlds (tld) VALUES ('PT');
INSERT INTO enum_tlds (tld) VALUES ('PW');
INSERT INTO enum_tlds (tld) VALUES ('PY');
INSERT INTO enum_tlds (tld) VALUES ('QA');
INSERT INTO enum_tlds (tld) VALUES ('RE');
INSERT INTO enum_tlds (tld) VALUES ('RO');
INSERT INTO enum_tlds (tld) VALUES ('RS');
INSERT INTO enum_tlds (tld) VALUES ('RU');
INSERT INTO enum_tlds (tld) VALUES ('RW');
INSERT INTO enum_tlds (tld) VALUES ('SA');
INSERT INTO enum_tlds (tld) VALUES ('SB');
INSERT INTO enum_tlds (tld) VALUES ('SC');
INSERT INTO enum_tlds (tld) VALUES ('SD');
INSERT INTO enum_tlds (tld) VALUES ('SE');
INSERT INTO enum_tlds (tld) VALUES ('SG');
INSERT INTO enum_tlds (tld) VALUES ('SH');
INSERT INTO enum_tlds (tld) VALUES ('SI');
INSERT INTO enum_tlds (tld) VALUES ('SJ');
INSERT INTO enum_tlds (tld) VALUES ('SK');
INSERT INTO enum_tlds (tld) VALUES ('SL');
INSERT INTO enum_tlds (tld) VALUES ('SM');
INSERT INTO enum_tlds (tld) VALUES ('SN');
INSERT INTO enum_tlds (tld) VALUES ('SO');
INSERT INTO enum_tlds (tld) VALUES ('SR');
INSERT INTO enum_tlds (tld) VALUES ('ST');
INSERT INTO enum_tlds (tld) VALUES ('SU');
INSERT INTO enum_tlds (tld) VALUES ('SV');
INSERT INTO enum_tlds (tld) VALUES ('SY');
INSERT INTO enum_tlds (tld) VALUES ('SZ');
INSERT INTO enum_tlds (tld) VALUES ('TC');
INSERT INTO enum_tlds (tld) VALUES ('TD');
INSERT INTO enum_tlds (tld) VALUES ('TEL');
INSERT INTO enum_tlds (tld) VALUES ('TF');
INSERT INTO enum_tlds (tld) VALUES ('TG');
INSERT INTO enum_tlds (tld) VALUES ('TH');
INSERT INTO enum_tlds (tld) VALUES ('TJ');
INSERT INTO enum_tlds (tld) VALUES ('TK');
INSERT INTO enum_tlds (tld) VALUES ('TL');
INSERT INTO enum_tlds (tld) VALUES ('TM');
INSERT INTO enum_tlds (tld) VALUES ('TN');
INSERT INTO enum_tlds (tld) VALUES ('TO');
INSERT INTO enum_tlds (tld) VALUES ('TP');
INSERT INTO enum_tlds (tld) VALUES ('TR');
INSERT INTO enum_tlds (tld) VALUES ('TRAVEL');
INSERT INTO enum_tlds (tld) VALUES ('TT');
INSERT INTO enum_tlds (tld) VALUES ('TV');
INSERT INTO enum_tlds (tld) VALUES ('TW');
INSERT INTO enum_tlds (tld) VALUES ('TZ');
INSERT INTO enum_tlds (tld) VALUES ('UA');
INSERT INTO enum_tlds (tld) VALUES ('UG');
INSERT INTO enum_tlds (tld) VALUES ('UK');
INSERT INTO enum_tlds (tld) VALUES ('UM');
INSERT INTO enum_tlds (tld) VALUES ('US');
INSERT INTO enum_tlds (tld) VALUES ('UY');
INSERT INTO enum_tlds (tld) VALUES ('UZ');
INSERT INTO enum_tlds (tld) VALUES ('VA');
INSERT INTO enum_tlds (tld) VALUES ('VC');
INSERT INTO enum_tlds (tld) VALUES ('VE');
INSERT INTO enum_tlds (tld) VALUES ('VG');
INSERT INTO enum_tlds (tld) VALUES ('VI');
INSERT INTO enum_tlds (tld) VALUES ('VN');
INSERT INTO enum_tlds (tld) VALUES ('VU');
INSERT INTO enum_tlds (tld) VALUES ('WF');
INSERT INTO enum_tlds (tld) VALUES ('WS');
INSERT INTO enum_tlds (tld) VALUES ('XN--0ZWM56D');
INSERT INTO enum_tlds (tld) VALUES ('XN--11B5BS3A9AJ6G');
INSERT INTO enum_tlds (tld) VALUES ('XN--80AKHBYKNJ4F');
INSERT INTO enum_tlds (tld) VALUES ('XN--9T4B11YI5A');
INSERT INTO enum_tlds (tld) VALUES ('XN--DEBA0AD');
INSERT INTO enum_tlds (tld) VALUES ('XN--G6W251D');
INSERT INTO enum_tlds (tld) VALUES ('XN--HGBK6AJ7F53BBA');
INSERT INTO enum_tlds (tld) VALUES ('XN--HLCJ6AYA9ESC7A');
INSERT INTO enum_tlds (tld) VALUES ('XN--JXALPDLP');
INSERT INTO enum_tlds (tld) VALUES ('XN--KGBECHTV');
INSERT INTO enum_tlds (tld) VALUES ('XN--ZCKZAH');
INSERT INTO enum_tlds (tld) VALUES ('YE');
INSERT INTO enum_tlds (tld) VALUES ('YT');
INSERT INTO enum_tlds (tld) VALUES ('YU');
INSERT INTO enum_tlds (tld) VALUES ('ZA');
INSERT INTO enum_tlds (tld) VALUES ('ZM');
INSERT INTO enum_tlds (tld) VALUES ('ZW');

-- function to test date moved by offset agains current date
CREATE OR REPLACE FUNCTION date_test(date, varchar)
RETURNS boolean
AS $$
SELECT $1 + ($2||' days')::interval <= CURRENT_DATE ;
$$ IMMUTABLE LANGUAGE SQL;

-- function to test date moved by offset agains current date with respect
-- to current time and time zone
CREATE OR REPLACE FUNCTION date_time_test(date, varchar, varchar, varchar)
RETURNS boolean
AS $$
SELECT $1 + ($2||' days')::interval + ($3||' hours')::interval 
       <= CURRENT_TIMESTAMP AT TIME ZONE $4;
$$ IMMUTABLE LANGUAGE SQL;

-- ========== 1. type ==============================
-- following views and one setting function is for global setting of all
-- states. there are view pro each type of object to catch states of ALL
-- objects. then function is defined that compare these states with
-- actual state and update states appropriatly. That function is long
-- running so it cannot be used for updating states online. That case
-- is handled in 2. type of functions 

-- view for actual domain states
-- ================= DOMAIN ========================
DROP VIEW domain_states;
CREATE VIEW domain_states AS
SELECT
  d.id AS object_id,
  o.historyid AS object_hid,
  COALESCE(osr.states,'{}') ||
  CASE WHEN date_test(d.exdate::date,ep_ex_not.val) 
            AND NOT (2 = ANY(COALESCE(osr.states,'{}'))) -- !renewProhibited
       THEN ARRAY[8] ELSE '{}' END ||  -- expirationWarning
  CASE WHEN date_test(d.exdate::date,'0')                
            AND NOT (2 = ANY(COALESCE(osr.states,'{}'))) -- !renewProhibited
       THEN ARRAY[9] ELSE '{}' END ||  -- expired
  CASE WHEN date_time_test(d.exdate::date,ep_ex_dns.val,ep_tm.val,ep_tz.val)
            AND NOT (2 = ANY(COALESCE(osr.states,'{}'))) -- !renewProhibited
       THEN ARRAY[10] ELSE '{}' END || -- unguarded
  CASE WHEN date_test(e.exdate::date,ep_val_not1.val)
       THEN ARRAY[11] ELSE '{}' END || -- validationWarning1
  CASE WHEN date_test(e.exdate::date,ep_val_not2.val)
       THEN ARRAY[12] ELSE '{}' END || -- validationWarning2
  CASE WHEN date_time_test(e.exdate::date,'0',ep_tm.val,ep_tz.val)
       THEN ARRAY[13] ELSE '{}' END || -- notValidated
  CASE WHEN d.nsset ISNULL 
       THEN ARRAY[14] ELSE '{}' END || -- nssetMissing
  CASE WHEN
    d.nsset ISNULL OR
    5 = ANY(COALESCE(osr.states,'{}')) OR                -- outzoneManual
    (((date_time_test(d.exdate::date,ep_ex_dns.val,ep_tm.val,ep_tz.val)
       AND NOT (2 = ANY(COALESCE(osr.states,'{}')))      -- !renewProhibited
      ) OR date_time_test(e.exdate::date,'0',ep_tm.val,ep_tz.val)) AND 
     NOT (6 = ANY(COALESCE(osr.states,'{}'))))           -- !inzoneManual
       THEN ARRAY[15] ELSE '{}' END || -- outzone
  CASE WHEN date_time_test(d.exdate::date,ep_ex_reg.val,ep_tm.val,ep_tz.val)
            AND NOT (2 = ANY(COALESCE(osr.states,'{}'))) -- !renewProhibited
            AND NOT (1 = ANY(COALESCE(osr.states,'{}'))) -- !deleteProhibited
       THEN ARRAY[17] ELSE '{}' END || -- deleteCandidate
  CASE WHEN date_test(d.exdate::date,ep_ex_let.val)
            AND NOT (2 = ANY(COALESCE(osr.states,'{}'))) -- !renewProhibited
       THEN ARRAY[19] ELSE '{}' END || -- deleteWarning
  CASE WHEN date_time_test(d.exdate::date,ep_ex_dns.val,ep_tm.val,ep_tz.val)
            AND NOT (2 = ANY(COALESCE(osr.states,'{}'))) -- !renewProhibited
            AND NOT (6 = ANY(COALESCE(osr.states,'{}'))) -- !inzoneManual
       THEN ARRAY[20] ELSE '{}' END    -- outzoneUnguarded
  AS states
FROM
  object_registry o,
  domain d
  LEFT JOIN enumval e ON (d.id=e.domainid)
  LEFT JOIN object_state_request_now osr ON (d.id=osr.object_id)
  JOIN enum_parameters ep_ex_not ON (ep_ex_not.id=3)
  JOIN enum_parameters ep_ex_dns ON (ep_ex_dns.id=4)
  JOIN enum_parameters ep_ex_let ON (ep_ex_let.id=5)
  JOIN enum_parameters ep_ex_reg ON (ep_ex_reg.id=6)
  JOIN enum_parameters ep_val_not1 ON (ep_val_not1.id=7)
  JOIN enum_parameters ep_val_not2 ON (ep_val_not2.id=8)
  JOIN enum_parameters ep_tm ON (ep_tm.id=9)
  JOIN enum_parameters ep_tz ON (ep_tz.id=10)
WHERE d.id=o.id;

-- view for actual nsset states
-- for NOW they are not deleted
-- ================= NSSET ========================
DROP VIEW nsset_states;
CREATE VIEW nsset_states AS
SELECT
  n.id AS object_id,
  o.historyid AS object_hid,
  COALESCE(osr.states,'{}') ||
  CASE WHEN NOT(d.nsset ISNULL) THEN ARRAY[16] ELSE '{}' END  -- ||
--  CASE WHEN n.id ISNULL AND
--            CAST(COALESCE(l.last_linked,o.crdate) AS DATE) 
--            + INTERVAL '6 month' + INTERVAL '14 hours' <= CURRENT_TIMESTAMP
--            AND NOT (1 = ANY(COALESCE(osr.states,'{}')))
--       THEN ARRAY[17] ELSE '{}' END 
  AS states
FROM
  object_registry o, nsset n
  LEFT JOIN (
    SELECT DISTINCT nsset FROM domain
  ) AS d ON (d.nsset=n.id)
--  LEFT JOIN (
--    SELECT object_id, MAX(valid_to) AS last_linked
--    FROM object_state
--    WHERE state_id=16 GROUP BY object_id
--  ) AS l ON (n.id=l.object_id)
  LEFT JOIN object_state_request_now osr ON (n.id=osr.object_id)
WHERE
  o.type=2 AND o.id=n.id;

-- view for actual contact states
-- for NOW they are not deleted
-- ================= CONTACT ========================
DROP VIEW contact_states;
CREATE VIEW contact_states AS
SELECT
  c.id AS object_id,
  o.historyid AS object_hid,
  COALESCE(osr.states,'{}') ||
  CASE WHEN NOT(cl.cid ISNULL) THEN ARRAY[16] ELSE '{}' END --||
--  CASE WHEN cl.cid ISNULL AND
--            CAST(COALESCE(l.last_linked,o.crdate) AS DATE) 
--            + INTERVAL '6 month' + INTERVAL '14 hours' <= CURRENT_TIMESTAMP
--            AND NOT (1 = ANY(COALESCE(osr.states,'{}')))
--       THEN ARRAY[17] ELSE '{}' END 
  AS states
FROM
  object_registry o, contact c
  LEFT JOIN (
    SELECT registrant AS cid FROM domain
    UNION
    SELECT contactid AS cid FROM domain_contact_map
    UNION
    SELECT contactid AS cid FROM nsset_contact_map
  ) AS cl ON (c.id=cl.cid)
--  LEFT JOIN (
--    SELECT object_id, MAX(valid_to) AS last_linked
--    FROM object_state
--    WHERE state_id=16 GROUP BY object_id
--  ) AS l ON (c.id=l.object_id)
    LEFT JOIN object_state_request_now osr ON (c.id=osr.object_id)
WHERE
  o.type=1 AND o.id=c.id;

-- in next function compared arrays need to be sorted
CREATE OR REPLACE FUNCTION array_sort_dist (ANYARRAY)
RETURNS ANYARRAY LANGUAGE SQL
AS $$
SELECT COALESCE(ARRAY(
    SELECT DISTINCT $1[s.i] AS "sort"
    FROM
        generate_series(array_lower($1,1), array_upper($1,1)) AS s(i)
    ORDER BY sort
),'{}');
$$ IMMUTABLE;

-- ================= UPDATE FUNCTION =================
-- CREATE LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION update_object_states()
RETURNS void
AS $$
BEGIN
  IF NOT EXISTS(
    SELECT relname FROM pg_class
    WHERE relname = 'tmp_object_state_change' AND relkind = 'r' AND
    pg_table_is_visible(oid)
  )
  THEN
    CREATE TEMPORARY TABLE tmp_object_state_change (
      object_id INTEGER,
      object_hid INTEGER,
      new_states INTEGER[],
      old_states INTEGER[]
    );
  ELSE
    TRUNCATE tmp_object_state_change;
  END IF;

  INSERT INTO tmp_object_state_change
  SELECT
    st.object_id, st.object_hid, st.states AS new_states, 
    COALESCE(o.states,'{}') AS old_states
  FROM (
    SELECT * FROM domain_states
    UNION
    SELECT * FROM contact_states
    UNION
    SELECT * FROM nsset_states
  ) AS st
  LEFT JOIN object_state_now o ON (st.object_id=o.object_id)
  WHERE array_sort_dist(st.states)!=COALESCE(array_sort_dist(o.states),'{}');

  INSERT INTO object_state (object_id,state_id,valid_from,ohid_from)
  SELECT c.object_id,e.id,CURRENT_TIMESTAMP,c.object_hid
  FROM tmp_object_state_change c, enum_object_states e
  WHERE e.id = ANY(c.new_states) AND e.id != ALL(c.old_states);

  UPDATE object_state SET valid_to=CURRENT_TIMESTAMP, ohid_to=c.object_hid
  FROM enum_object_states e, tmp_object_state_change c
  WHERE e.id = ANY(c.old_states) AND e.id != ALL(c.new_states)
  AND e.id=object_state.state_id and c.object_id=object_state.object_id 
  AND object_state.valid_to ISNULL;
END;
$$ LANGUAGE plpgsql;

-- ========== 2. type ==============================
-- following functions and triggers are for automatic state update
-- as a reaction on normal EPP commands.

-- RACE CONTIONS! :
-- there are some places where race conditions can play a role. this is
-- because of sharing of nsset and contacts. their status 'linked' is
-- updated when they appear in EPP commands on others object and because
-- of parallel execution of these commands, linked status is 'shared resource'.
--  1. setting linked state. situation when two transactions want to add 
--     linked state is handled by UNIQUE constraint and EXCEPTION 
--     catching in status_set_state function. second setting is let to fail
--     alternative is to lock all table with states which is inefficient
--  2. clearing linked state. when test is done to clear a state, there
--     can appear transaction that change results of this before clear so
--     test and clear need to be atomic. this must be done by row locking
--     of linked state row in states table. this is done by function
--     status_clear_lock.
CREATE OR REPLACE FUNCTION status_clear_lock(integer, integer)
RETURNS boolean
AS $$
SELECT id IS NOT NULL FROM object_state 
WHERE object_id=$1 AND state_id=$2 AND valid_to IS NULL FOR UPDATE;
$$ LANGUAGE SQL;

-- set state of object if condition is satisfied. use optimistic access
-- so there is no need for locking, could be enhanced by checking of 
-- presence of state (to minimize number of failures in unique constraint)
-- but expectation is that this is faster
-- this function only set state, it won't clean it (see next function) 
CREATE OR REPLACE FUNCTION status_set_state(
  _cond BOOL, _state_id INTEGER, _object_id INTEGER
) RETURNS VOID AS $$
 BEGIN
   IF _cond THEN
     -- optimistic access, don't check if status exists
     -- but may fail on UNIQUE constraint, so catching exception 
     INSERT INTO object_state (object_id, state_id, valid_from)
     VALUES (_object_id, _state_id, CURRENT_TIMESTAMP);
   END IF;
 EXCEPTION
   WHEN UNIQUE_VIOLATION THEN
   -- do nothing
 END;
$$ LANGUAGE plpgsql;

-- clear state of object
CREATE OR REPLACE FUNCTION status_clear_state(
  _cond BOOL, _state_id INTEGER, _object_id INTEGER
) RETURNS VOID AS $$
 BEGIN
   IF NOT _cond THEN
     -- condition (valid_to IS NULL) is essential to avoid closing closed
     -- state
     UPDATE object_state SET valid_to = CURRENT_TIMESTAMP
     WHERE state_id = _state_id AND valid_to IS NULL 
     AND object_id = _object_id;
   END IF;
 END;
$$ LANGUAGE plpgsql;

-- set state of object and clear state of object according to condition
CREATE OR REPLACE FUNCTION status_update_state(
  _cond BOOL, _state_id INTEGER, _object_id INTEGER
) RETURNS VOID AS $$
 DECLARE
   _num INTEGER;
 BEGIN
   -- don't know if it's faster to not test condition twise or call EXECUTE
   -- that immidietely return (removing IF), guess is twice test is faster
   IF _cond THEN
     EXECUTE status_set_state(_cond, _state_id, _object_id);
   ELSE
     EXECUTE status_clear_state(_cond, _state_id, _object_id);
   END IF;
 END;
$$ LANGUAGE plpgsql;

-- trigger function to handle dependant state. some states depends on others
-- so trigger is fired on state table after every change and
-- dependant states are updated aproprietly
CREATE OR REPLACE FUNCTION status_update_object_state() RETURNS TRIGGER AS $$
  DECLARE
    _states INTEGER[];
  BEGIN
    IF NEW.state_id = ANY (ARRAY[5,6,10,13,14]) THEN
      -- activation is only done on states that are relevant for
      -- dependant states to stop RECURSION
      SELECT array_accum(state_id) INTO _states FROM object_state
          WHERE valid_to IS NULL AND object_id = NEW.object_id;
      -- set or clear status 15 (outzone)
      EXECUTE status_update_state(
        (14 = ANY (_states)) OR -- nsset is null
        (5  = ANY (_states)) OR -- serverOutzoneManual
        (NOT (6 = ANY (_states)) AND -- not serverInzoneManual
          ((10 = ANY (_states)) OR -- unguarded
           (13 = ANY (_states)))),  -- not validated
        15, NEW.object_id -- => set outzone
      );
      -- set or clear status 15 (outzoneUnguarded)
      EXECUTE status_update_state(
        NOT (6 = ANY (_states)) AND -- not serverInzoneManual
            (10 = ANY (_states)), -- unguarded
        20, NEW.object_id -- => set ouzoneUnguarded
      );
    END IF;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

-- update history id of object at status opening and closing
-- it's useful to catch history id of object on state opening and closing
-- to centralize this setting, it's done by trigger here
CREATE OR REPLACE FUNCTION status_update_hid() RETURNS TRIGGER AS $$
  BEGIN
    IF TG_OP = 'UPDATE' AND NEW.ohid_to ISNULL THEN
      SELECT historyid INTO NEW.ohid_to 
      FROM object_registry WHERE id=NEW.object_id;
    ELSE IF TG_OP = 'INSERT' AND NEW.ohid_from ISNULL THEN
        SELECT historyid INTO NEW.ohid_from 
        FROM object_registry WHERE id=NEW.object_id;
      END IF;
    END IF;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

-- trigger to update state of domain, fired with every change on
-- on domain table
CREATE OR REPLACE FUNCTION status_update_domain() RETURNS TRIGGER AS $$
  DECLARE
    _num INTEGER;
    _nsset_old INTEGER;
    _registrant_old INTEGER;
    _nsset_new INTEGER;
    _registrant_new INTEGER;
    _ex_not VARCHAR;
    _ex_dns VARCHAR;
    _ex_let VARCHAR;
--    _ex_reg VARCHAR;
    _proc_tm VARCHAR;
    _proc_tz VARCHAR;
  BEGIN
    _nsset_old := NULL;
    _registrant_old := NULL;
    _nsset_new := NULL;
    _registrant_new := NULL;
    SELECT val INTO _ex_not FROM enum_parameters WHERE id=3;
    SELECT val INTO _ex_dns FROM enum_parameters WHERE id=4;
    SELECT val INTO _ex_let FROM enum_parameters WHERE id=5;
--    SELECT val INTO _ex_reg FROM enum_parameters WHERE id=6;
    SELECT val INTO _proc_tm FROM enum_parameters WHERE id=9;
    SELECT val INTO _proc_tz FROM enum_parameters WHERE id=10;
    -- is it INSERT operation
    IF TG_OP = 'INSERT' THEN
      _registrant_new := NEW.registrant;
      _nsset_new := NEW.nsset;
      -- we ignore exdate, for new domain it shouldn't influence its state
      -- state: nsset missing
      EXECUTE status_update_state(
        NEW.nsset ISNULL, 14, NEW.id
      );
    -- is it UPDATE operation
    ELSIF TG_OP = 'UPDATE' THEN
      IF NEW.registrant <> OLD.registrant THEN
        _registrant_old := OLD.registrant;
        _registrant_new := NEW.registrant;
      END IF;
      IF COALESCE(NEW.nsset,0) <> COALESCE(OLD.nsset,0) THEN
        _nsset_old := OLD.nsset;
        _nsset_new := NEW.nsset;
      END IF;
      -- take care of all domain statuses
      IF NEW.exdate <> OLD.exdate THEN
        -- at the first sight it seems that there should be checking
        -- for renewProhibited state before setting all of these states
        -- as it's done in global (1. type) views
        -- but the point is that when renewProhibited is set
        -- there is no way to change exdate so this situation can never happen 
        -- state: expiration warning
        EXECUTE status_update_state(
          date_test(NEW.exdate::date,_ex_not),
          8, NEW.id
        );
        -- state: expired
        EXECUTE status_update_state(
          date_test(NEW.exdate::date,'0'),
          9, NEW.id
        );
        -- state: unguarded
        EXECUTE status_update_state(
          date_time_test(NEW.exdate::date,_ex_dns,_proc_tm,_proc_tz), 
          10, NEW.id
        );
        -- state: deleteWarning
        EXECUTE status_update_state(
          date_test(NEW.exdate::date,_ex_let),
          19, NEW.id
        );
        -- state: delete candidate (seems useless - cannot switch after del)
        -- for now delete state will be set only globaly
--        EXECUTE status_update_state(
--          date_time_test(NEW.exdate::date,_ex_reg,_proc_tm,_proc_tz), 
--          17, NEW.id
--        );
      END IF; -- change in exdate
      IF COALESCE(NEW.nsset,0) <> COALESCE(OLD.nsset,0) THEN
        -- state: nsset missing
        EXECUTE status_update_state(
          NEW.nsset ISNULL, 14, NEW.id
        );
      END IF; -- change in nsset
    -- is it DELETE operation
    ELSIF TG_OP = 'DELETE' THEN
      _registrant_old := OLD.registrant;
      _nsset_old := OLD.nsset; -- may be NULL!
      -- exdate is meaningless when deleting (probably)
    END IF;

    -- add registrant's linked status if there is none
    EXECUTE status_set_state(
      _registrant_new IS NOT NULL, 16, _registrant_new
    );
    -- add nsset's linked status if there is none
    EXECUTE status_set_state(
      _nsset_new IS NOT NULL, 16, _nsset_new
    );
    -- remove registrant's linked status if not bound
    -- locking must be done (see comment above)
    IF _registrant_old IS NOT NULL AND 
       status_clear_lock(_registrant_old, 16) IS NOT NULL 
    THEN
      SELECT count(*) INTO _num FROM domain
          WHERE registrant = OLD.registrant;
      IF _num = 0 THEN
        SELECT count(*) INTO _num FROM domain_contact_map
            WHERE contactid = OLD.registrant;
        IF _num = 0 THEN
          SELECT count(*) INTO _num FROM nsset_contact_map
              WHERE contactid = OLD.registrant;
          EXECUTE status_clear_state(_num <> 0, 16, OLD.registrant);
        END IF;
      END IF;
    END IF;
    -- remove nsset's linked status if not bound
    -- locking must be done (see comment above)
    IF _nsset_old IS NOT NULL AND
       status_clear_lock(_nsset_old, 16) IS NOT NULL  
    THEN
      SELECT count(*) INTO _num FROM domain WHERE nsset = OLD.nsset;
      EXECUTE status_clear_state(_num <> 0, 16, OLD.nsset);
    END IF;
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION status_update_enumval() RETURNS TRIGGER AS $$
  DECLARE
    _num INTEGER;
  BEGIN
    -- is it UPDATE operation
    IF TG_OP = 'UPDATE' AND NEW.exdate <> OLD.exdate THEN
      -- state: validation warning 1
      EXECUTE status_update_state(
        NEW.exdate::date - INTERVAL '30 days' <= CURRENT_DATE, 11, NEW.domainid
      );
      -- state: validation warning 2
      EXECUTE status_update_state(
        NEW.exdate::date - INTERVAL '15 days' <= CURRENT_DATE, 12, NEW.domainid
      );
      -- state: not validated
      EXECUTE status_update_state(
        NEW.exdate::date + INTERVAL '14 hours' <= CURRENT_TIMESTAMP, 13, NEW.domainid
      );
    END IF;
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION status_update_contact_map() RETURNS TRIGGER AS $$
  DECLARE
    _num INTEGER;
    _contact_old INTEGER;
    _contact_new INTEGER;
  BEGIN
    _contact_old := NULL;
    _contact_new := NULL;
    -- is it INSERT operation
    IF TG_OP = 'INSERT' THEN
      _contact_new := NEW.contactid;
    -- is it UPDATE operation
    ELSIF TG_OP = 'UPDATE' THEN
      IF NEW.contactid <> OLD.contactid THEN
        _contact_old := OLD.contactid;
        _contact_new := NEW.contactid;
      END IF;
    -- is it DELETE operation
    ELSIF TG_OP = 'DELETE' THEN
      _contact_old := OLD.contactid;
    END IF;

    -- add contact's linked status if there is none
    EXECUTE status_set_state(
      _contact_new IS NOT NULL, 16, _contact_new
    );
    -- remove contact's linked status if not bound
    -- locking must be done (see comment above)
    IF _contact_old IS NOT NULL AND
       status_clear_lock(_contact_old, 16) IS NOT NULL 
    THEN
      SELECT count(*) INTO _num FROM domain WHERE registrant = OLD.contactid;
      IF _num = 0 THEN
        SELECT count(*) INTO _num FROM domain_contact_map
            WHERE contactid = OLD.contactid;
        IF _num = 0 THEN
          SELECT count(*) INTO _num FROM nsset_contact_map
              WHERE contactid = OLD.contactid;
          EXECUTE status_clear_state(_num <> 0, 16, OLD.contactid);
        END IF;
      END IF;
    END IF;
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;

-- object history tables are filled after normal object tables (i.e. domain)
-- and so when new state is generated as result of new row in normal 
-- table, no history table is available to reference in ohid_from
-- this trigger fix this be filling unfilled ohid_from after insert
-- into history
CREATE OR REPLACE FUNCTION object_history_insert() RETURNS TRIGGER AS $$
  BEGIN
    UPDATE object_state SET ohid_from=NEW.historyid 
    WHERE ohid_from ISNULL AND object_id=NEW.id;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

CREATE TABLE action_elements(
  id SERIAL PRIMARY KEY,
  actionid INTEGER REFERENCES action,
  elementid INTEGER,
  value VARCHAR(255)
);

CREATE INDEX action_elements_value_idx ON action_elements (value);
CREATE INDEX action_elements_elementid_idx ON action_elements (elementid);

SELECT SETVAL('zone_id_seq',(SELECT MAX(id)+1 FROM zone),'f');
SELECT SETVAL('registrar_id_seq',(SELECT MAX(id)+1 FROM registrar),'f');
SELECT SETVAL('registraracl_id_seq',(SELECT MAX(id)+1 FROM registraracl),'f');
SELECT SETVAL('registrarinvoice_id_seq',(SELECT MAX(id)+1 FROM registrarinvoice),'f');

