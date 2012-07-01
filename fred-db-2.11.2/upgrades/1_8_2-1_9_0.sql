--
--  block requests answer emails
--

INSERT INTO mail_type (id, name, subject) VALUES (20, 'request_block', 'Informace o vyřízení žádosti / Information about processing of request ');
INSERT INTO mail_templates (id, contenttype, footer, template) VALUES
(20, 'plain', 1,
'English version of the e-mail is entered below the Czech version

Informace o vyřízení žádosti

Vážený zákazníku,

   na základě Vaší žádosti podané prostřednictvím webového formuláře
na stránkách sdružení dne <?cs var:reqdate ?>, které bylo přiděleno identifikační 
číslo <?cs var:reqid ?>, Vám oznamujeme, že požadovaná žádost o <?cs if:otype == #1 ?>zablokování<?cs elif:otype == #2 ?>odblokování<?cs /if ?>
<?cs if:rtype == #1 ?>změny dat<?cs elif:rtype == #2 ?>transferu k jinému registrátorovi<?cs /if ?> pro <?cs if:type == #3 ?>doménu<?cs elif:type == #1 ?>kontakt s identifikátorem<?cs elif:type == #2 ?>sadu nameserverů s identifikátorem<?cs /if ?> <?cs var:handle ?> 
byla úspěšně realizována.  
<?cs if:otype == #1 ?>
U <?cs if:type == #3 ?>domény<?cs elif:type == #1 ?>kontaktu s identifikátorem<?cs elif:type == #2 ?>sady nameserverů s identifikátorem<?cs /if ?> <?cs var:handle ?> nebude možné provést 
<?cs if:rtype == #1 ?>změnu dat<?cs elif:rtype == #2 ?>transfer k jinému registrátorovi <?cs /if ?> až do okamžiku, kdy tuto blokaci 
zrušíte pomocí příslušného formuláře na stránkách sdružení.
<?cs /if?>
                                             S pozdravem
                                             podpora <?cs var:defaults.company ?>

Information about processing of request

Dear customer,

   based on your request submitted via the web form on the association
pages on <?cs var:reqdate ?>, which received the identification number 
<?cs var:reqid ?>, we are announcing that your request for <?cs if:otype == #1 ?>blocking<?cs elif:otype == #2 ?>unblocking<?cs /if ?>
<?cs if:rtype == #1 ?>data changes<?cs elif:rtype == #2 ?>transfer to other registrar<?cs /if ?> for <?cs if:type == #3 ?>domain name<?cs elif:type == #1 ?>contact with identifier<?cs elif:type == #2 ?>NS set with identifier<?cs /if ?> <?cs var:handle ?> 
has been realized.
<?cs if:otype == #1 ?>
No <?cs if:rtype == #1 ?>data changes<?cs elif:rtype == #2 ?>transfer to other registrar<?cs /if ?> of <?cs if:type == #3 ?>domain name<?cs elif:type == #1 ?>contact with identifier<?cs elif:type == #2 ?>NS set with identifier<?cs /if ?> <?cs var:handle ?> 
will be possible until you cancel the blocking option using the 
applicable form on association pages. 
<?cs /if?>
                                             Yours sincerely
                                             support <?cs var:defaults.company ?>
');
INSERT INTO mail_type_template_map (typeid, templateid) VALUES (20, 20);


--
-- changing domain.exdate type from timestamp to date
--

-- need convert exdate to CET zone
UPDATE domain SET exdate = exdate::timestamptz at time zone 'CET'
  WHERE exdate::date != (exdate::timestamptz at time zone 'CET')::date;
UPDATE domain_history SET exdate = exdate::timestamptz at time zone 'CET' 
  FROM object_registry o 
  WHERE domain_history.historyid=o.historyid AND o.erdate ISNULL 
  AND exdate::date != (exdate::timestamptz at time zone 'CET')::date;
-- drop domain_states view to allow alter table command
DROP VIEW domain_states;
-- alter table 
ALTER TABLE domain ALTER COLUMN exdate TYPE date;
ALTER TABLE domain_history ALTER COLUMN exdate TYPE date;
-- recreate domain_states view - removed exdate cast to date its date already
CREATE VIEW domain_states AS
SELECT
  d.id AS object_id,
  o.historyid AS object_hid,
  COALESCE(osr.states,'{}') ||
  CASE WHEN date_test(d.exdate,ep_ex_not.val) 
            AND NOT (2 = ANY(COALESCE(osr.states,'{}'))) -- !renewProhibited
       THEN ARRAY[8] ELSE '{}' END ||  -- expirationWarning
  CASE WHEN date_test(d.exdate,'0')                
            AND NOT (2 = ANY(COALESCE(osr.states,'{}'))) -- !renewProhibited
       THEN ARRAY[9] ELSE '{}' END ||  -- expired
  CASE WHEN date_time_test(d.exdate,ep_ex_dns.val,ep_tm.val,ep_tz.val)
            AND NOT (2 = ANY(COALESCE(osr.states,'{}'))) -- !renewProhibited
       THEN ARRAY[10] ELSE '{}' END || -- unguarded
  CASE WHEN date_test(e.exdate,ep_val_not1.val)
       THEN ARRAY[11] ELSE '{}' END || -- validationWarning1
  CASE WHEN date_test(e.exdate,ep_val_not2.val)
       THEN ARRAY[12] ELSE '{}' END || -- validationWarning2
  CASE WHEN date_time_test(e.exdate,'0',ep_tm.val,ep_tz.val)
       THEN ARRAY[13] ELSE '{}' END || -- notValidated
  CASE WHEN d.nsset ISNULL 
       THEN ARRAY[14] ELSE '{}' END || -- nssetMissing
  CASE WHEN
    d.nsset ISNULL OR
    5 = ANY(COALESCE(osr.states,'{}')) OR                -- outzoneManual
    (((date_time_test(d.exdate,ep_ex_dns.val,ep_tm.val,ep_tz.val)
       AND NOT (2 = ANY(COALESCE(osr.states,'{}')))      -- !renewProhibited
      ) OR date_time_test(e.exdate,'0',ep_tm.val,ep_tz.val)) AND 
     NOT (6 = ANY(COALESCE(osr.states,'{}'))))           -- !inzoneManual
       THEN ARRAY[15] ELSE '{}' END || -- outzone
  CASE WHEN date_time_test(d.exdate,ep_ex_reg.val,ep_tm.val,ep_tz.val)
            AND NOT (2 = ANY(COALESCE(osr.states,'{}'))) -- !renewProhibited
            AND NOT (1 = ANY(COALESCE(osr.states,'{}'))) -- !deleteProhibited
       THEN ARRAY[17] ELSE '{}' END || -- deleteCandidate
  CASE WHEN date_test(d.exdate,ep_ex_let.val)
            AND NOT (2 = ANY(COALESCE(osr.states,'{}'))) -- !renewProhibited
       THEN ARRAY[19] ELSE '{}' END || -- deleteWarning
  CASE WHEN date_time_test(d.exdate,ep_ex_dns.val,ep_tm.val,ep_tz.val)
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

--
--  block requests changes and new tables
-- 

ALTER TABLE object_state_request ALTER COLUMN valid_from SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE object_state_request ALTER COLUMN crdate SET DEFAULT CURRENT_TIMESTAMP;

-- Public requests

CREATE TABLE public_request (
  id serial NOT NULL PRIMARY KEY,
  request_type smallint NOT NULL, -- vsechny typy zadosti
  epp_action_id integer REFERENCES action(id),
  create_time timestamp without time zone DEFAULT now() NOT NULL,
  status smallint DEFAULT 1 NOT NULL,
  resolve_time timestamp without time zone,
  reason character varying(512),
  email_to_answer character varying(255),
  answer_email_id integer REFERENCES mail_archive(id)
);

comment on table public_request is 'table of general requests give in by public users';
comment on column public_request.request_type is 'code of request';
comment on column public_request.epp_action_id is 'reference on action when request is submitted by registrar via EPP protocol (otherwise NULL)';
comment on column public_request.create_time is 'request creation time';
comment on column public_request.status is 'code of request actual status';
comment on column public_request.resolve_time is 'time when request was processed (closed)';
comment on column public_request.reason is 'reason';
comment on column public_request.email_to_answer is 'manual entered email by user for sending answer (if it is automatic from object contact it is NULL)';
comment on column public_request.answer_email_id is 'reference to mail which was send after request was processed';


CREATE TABLE public_request_objects_map (
  request_id integer REFERENCES public_request(id),
  object_id integer REFERENCES object_registry(id),
  
);

comment on table public_request_objects_map is 'table with objects associated with given request';

CREATE TABLE public_request_state_request_map (
  state_request_id integer PRIMARY KEY REFERENCES object_state_request(id),
  block_request_id integer NOT NULL REFERENCES public_request(id),
  unblock_request_id integer REFERENCES public_request(id)
);

comment on table public_request_state_request_map is 'table with state request associated with given request';

--
-- migration of auth_info_requests into new public_request
--

INSERT INTO public_request 
  SELECT id,request_type-1,epp_action_id,create_time,status-1,resolve_time,reason,email_to_answer,answer_email_id 
  FROM auth_info_requests;

INSERT INTO public_request_objects_map (request_id,object_id) 
  SELECT a.id,oh.id 
  FROM auth_info_requests a 
    JOIN object_history oh ON (a.object_id=oh.historyid);

SELECT setval('public_request_id_seq',(select last_value from auth_info_requests_id_seq));

-- 
-- allow update state of individual object
--

DROP FUNCTION update_object_states();
CREATE OR REPLACE FUNCTION update_object_states(int)
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

  IF $1 = 0
  THEN
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
  ELSE
    -- domain
    INSERT INTO tmp_object_state_change
    SELECT
      st.object_id, st.object_hid, st.states AS new_states, 
      COALESCE(o.states,'{}') AS old_states
    FROM domain_states st
    LEFT JOIN object_state_now o ON (st.object_id=o.object_id)
    WHERE array_sort_dist(st.states)!=COALESCE(array_sort_dist(o.states),'{}')
    AND st.object_id=$1;
    -- contact
    INSERT INTO tmp_object_state_change
    SELECT
      st.object_id, st.object_hid, st.states AS new_states, 
      COALESCE(o.states,'{}') AS old_states
    FROM contact_states st
    LEFT JOIN object_state_now o ON (st.object_id=o.object_id)
    WHERE array_sort_dist(st.states)!=COALESCE(array_sort_dist(o.states),'{}')
    AND st.object_id=$1;
    -- nsset
    INSERT INTO tmp_object_state_change
    SELECT
      st.object_id, st.object_hid, st.states AS new_states, 
      COALESCE(o.states,'{}') AS old_states
    FROM nsset_states st
    LEFT JOIN object_state_now o ON (st.object_id=o.object_id)
    WHERE array_sort_dist(st.states)!=COALESCE(array_sort_dist(o.states),'{}')
    AND st.object_id=$1;
  END IF;

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

CREATE INDEX object_registry_historyid_idx ON object_registry (historyid);

UPDATE enum_object_states_desc 
SET description='Není povoleno prodloužení registrace objektu' 
WHERE state_id=2 AND lang='CS';

UPDATE enum_object_states_desc 
SET description='Není povolena změna určeného registrátora' 
WHERE state_id=3 AND lang='CS';
