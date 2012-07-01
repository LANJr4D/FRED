---
--- summary upgrade script including all parts (mainly for fred-manager use)
---

\i 2_2_0-2_3_0-ddl.sql
\i 2_2_0-2_3_0-logger-ddl.sql
\i 2_2_0-2_3_0-dml.sql
\i 2_2_0-2_3_0-logger-dml.sql


---
--- all in same database set request table sequence beginning
---
SELECT setval('request_id_seq', (SELECT max(id) FROM action));

