
-- rename columns in request_type
ALTER TABLE request_type RENAME COLUMN service TO service_id;
ALTER TABLE request_type RENAME COLUMN status TO name;


-- rename columns in request
ALTER TABLE request RENAME COLUMN service TO service_id;
ALTER TABLE request RENAME COLUMN action_type TO request_type_id;

-- rename columns in request_data
ALTER TABLE request_data RENAME COLUMN entry_time_begin TO request_time_begin;
ALTER TABLE request_data RENAME COLUMN entry_service TO request_service_id;
ALTER TABLE request_data RENAME COLUMN entry_monitoring TO request_monitoring;
ALTER TABLE request_data RENAME COLUMN entry_id TO request_id;


-- rename columns in request_property_value
ALTER TABLE request_property_value RENAME COLUMN entry_time_begin TO request_time_begin;
ALTER TABLE request_property_value RENAME COLUMN entry_service TO request_service_id;
ALTER TABLE request_property_value RENAME COLUMN entry_monitoring TO request_monitoring;
ALTER TABLE request_property_value RENAME COLUMN entry_id TO request_id;
ALTER TABLE request_property_value RENAME COLUMN name_id TO property_name_id;

-- rename table request_property
ALTER TABLE request_property RENAME TO request_property_name;
ALTER SEQUENCE request_property_id_seq RENAME TO request_property_name_id_seq;

-- update procedures & rules

/*
WE DON'T NEED IT HERE SINCE IT'S ALREADY IN ANOTHER SCRIPT

CREATE OR REPLACE FUNCTION tr_request(id INTEGER, time_begin TIMESTAMP WITHOUT TIME ZONE, time_end TIMESTAMP WITHOUT TIME ZONE, source_ip INET, service_id INTEGER, request_type_id INTEGER, session_id INTEGER, user_name VARCHAR(255), is_monitoring BOOLEAN ) RETURNS VOID AS $tr_request$
DECLARE 
        table_name VARCHAR(50);
        stmt       TEXT;
BEGIN
        table_name = quote_ident('request_' || partition_postfix(time_begin, service_id, is_monitoring));

        stmt := 'INSERT INTO ' || table_name || ' (id, time_begin, time_end, source_ip, service_id, request_type_id, session_id, user_name, is_monitoring) VALUES (' 
                || COALESCE(id::TEXT, 'NULL')           || ', ' 
                || COALESCE(quote_literal(time_begin), 'NULL')           || ', '
                || COALESCE(quote_literal(time_end), 'NULL')             || ', '
                || COALESCE(quote_literal(host(source_ip)), 'NULL')      || ', '
                || COALESCE(service_id::TEXT, 'NULL')      || ', '
                || COALESCE(request_type_id::TEXT, 'NULL')  || ', '
                || COALESCE(session_id::TEXT, 'NULL')   || ', '
                || COALESCE(quote_literal(user_name), 'NULL')            || ', '
                || '''' || bool_to_str(is_monitoring)   || ''') ';
        
        -- raise notice 'request Generated insert: %', stmt;
        EXECUTE stmt;

EXCEPTION
        WHEN undefined_table THEN
        BEGIN
                PERFORM create_tbl_request(time_begin, service_id, is_monitoring);
        
                EXECUTE stmt;
        END;
END;
$tr_request$ LANGUAGE plpgsql;
*/

CREATE OR REPLACE FUNCTION tr_request_data(request_time_begin timestamp, request_service_id INTEGER,  request_monitoring BOOLEAN, request_id INTEGER, content TEXT, is_response BOOLEAN) RETURNS VOID AS $tr_request_data$
DECLARE 
        table_name VARCHAR(50);
        stmt  TEXT;
BEGIN
        table_name := quote_ident('request_data_' || partition_postfix(request_time_begin, request_service_id, request_monitoring));
        stmt := 'INSERT INTO ' || table_name || '(request_time_begin, request_service_id, request_monitoring, request_id,  content, is_response) VALUES (' 
            || COALESCE(quote_literal(request_time_begin), 'NULL')                 || ', ' 
            || COALESCE(request_service_id::TEXT, 'NULL')            || ', '
            || '''' || bool_to_str(request_monitoring)            || ''', ' 
            || COALESCE(request_id::TEXT, 'NULL')                 || ', ' 
            || COALESCE(quote_literal(content), 'NULL')                          || ', '
            || COALESCE('''' || bool_to_str(is_response) || '''' , 'NULL') || ') ';  

        -- raise notice 'request_data Generated insert: %', stmt;
        EXECUTE stmt;

EXCEPTION
        WHEN undefined_table THEN
        BEGIN
                PERFORM create_tbl_request_data(request_time_begin, request_service_id, request_monitoring);
        
                EXECUTE stmt;
        END;
END;
$tr_request_data$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tr_request_property_value(request_time_begin TIMESTAMP WITHOUT TIME ZONE, request_service_id INTEGER, request_monitoring BOOLEAN, id INTEGER, request_id INTEGER, property_name_id INTEGER, value TEXT, output BOOLEAN, parent_id INTEGER) RETURNS VOID AS $tr_request_property_value$
DECLARE 
        table_name VARCHAR(50);
        stmt  TEXT;
BEGIN
        table_name := quote_ident( 'request_property_value_' || partition_postfix(request_time_begin, request_service_id, request_monitoring));
        stmt := 'INSERT INTO ' || table_name || '(request_time_begin, request_service_id, request_monitoring, id, request_id, property_name_id, value, output, parent_id) VALUES (' 
            || COALESCE(quote_literal(request_time_begin), 'NULL')    || ', ' 
            || COALESCE(request_service_id::TEXT, 'NULL')                || ', '
            || '''' || bool_to_str(request_monitoring)                || ''', '
            || COALESCE(id::TEXT, 'NULL')                           || ', '
            || COALESCE(request_id::TEXT, 'NULL')                     || ', '
            || COALESCE(property_name_id::TEXT, 'NULL')                      || ', '
            || COALESCE(quote_literal(value), 'NULL')               || ', '
            || COALESCE('''' || bool_to_str(output) || '''', 'NULL') || ', ' 
            || COALESCE(parent_id::TEXT, 'NULL')                    || ')'; 
        -- raise notice 'request_property_value Generated insert: %', stmt;
        EXECUTE stmt;

EXCEPTION
        WHEN undefined_table THEN
        BEGIN
                PERFORM create_tbl_request_property_value(request_time_begin, request_service_id, request_monitoring);
        
                EXECUTE stmt;
        END;
END;
$tr_request_property_value$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION partition_postfix(rec_time TIMESTAMP WITHOUT TIME ZONE, serv INTEGER, is_monitoring BOOLEAN ) RETURNS VARCHAR(40) AS 
$partition_postfix_alt$
DECLARE 
        date_part VARCHAR(5);
        service_postfix VARCHAR(10);
BEGIN
        date_part := to_char(date_trunc('month', rec_time), 'YY_MM');

        IF (serv = -1) THEN
                RETURN date_part;
        elsif (is_monitoring) THEN
                RETURN 'mon_' || date_part;     
        ELSE
                SELECT partition_postfix into service_postfix from service where id = serv;
                RETURN service_postfix || date_part;
        END IF;
END;
$partition_postfix_alt$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_tbl_request(time_begin TIMESTAMP WITHOUT TIME ZONE, service_id INTEGER, monitoring BOOLEAN) RETURNS VOID AS $create_tbl_request$
DECLARE 
        table_name VARCHAR(60);
        create_table    TEXT;
        spec_alter_table TEXT;
        month INTEGER;
        lower TIMESTAMP WITHOUT TIME ZONE;
        upper  TIMESTAMP WITHOUT TIME ZONE;

BEGIN
        table_name := quote_ident('request' || '_' || partition_postfix(time_begin, service_id, monitoring));

        LOCK TABLE request IN SHARE UPDATE EXCLUSIVE MODE;

        lower := to_char(date_trunc('month', time_begin), 'YYYY-MM-DD');
        upper := to_char(date_trunc('month', time_begin + interval '1 month'), 'YYYY-MM-DD');

-- CREATE table
        IF monitoring = true THEN
                -- special constraints for monitoring table
                create_table := 'CREATE TABLE ' || table_name || '    (CHECK (time_begin >= TIMESTAMP ''' || lower || ''' AND time_begin < TIMESTAMP ''' 
                || upper || ''' AND is_monitoring = ''' || bool_to_str(monitoring) || ''') ) INHERITS (request)';
        ELSE
                create_table := 'CREATE TABLE ' || table_name || '    (CHECK (time_begin >= TIMESTAMP ''' || lower || ''' AND time_begin < TIMESTAMP ''' 
                || upper || ''' AND service_id = ' || service_id || ' AND is_monitoring = ''' || bool_to_str(monitoring) || ''') ) INHERITS (request)';          
        END IF; 
         
        
        spec_alter_table := 'ALTER TABLE ' || table_name || ' ADD PRIMARY KEY (id); ';

        EXECUTE create_table;
        EXECUTE spec_alter_table;

        PERFORM create_indexes_request(table_name);

EXCEPTION
    WHEN duplicate_table THEN
        NULL;
END;
$create_tbl_request$ LANGUAGE plpgsql;

/** parameter table_name must already be processed by quote_ident
*/
CREATE OR REPLACE FUNCTION create_indexes_request(table_name VARCHAR(50)) RETURNS VOID AS $create_indexes_request$
DECLARE 
        create_indexes TEXT;
BEGIN
        create_indexes := 'CREATE INDEX ' || table_name || '_time_begin_idx ON ' || table_name || '(time_begin); CREATE INDEX ' 
                                        || table_name || '_time_end_idx ON ' || table_name || '(time_end); CREATE INDEX ' 
                                        || table_name || '_source_ip_idx ON ' || table_name || '(source_ip); CREATE INDEX ' 
                                        || table_name || '_service_idx ON ' || table_name || '(service_id); CREATE INDEX ' 
                                        || table_name || '_action_type_idx ON ' || table_name || '(request_type_id); CREATE INDEX '
                                        || table_name || '_monitoring_idx ON ' || table_name || '(is_monitoring);';
        EXECUTE create_indexes;
END;
$create_indexes_request$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_tbl_request_data(time_begin TIMESTAMP WITHOUT TIME ZONE, service_id INTEGER, monitoring BOOLEAN) RETURNS VOID AS $create_tbl_request_data$
DECLARE 
        table_name VARCHAR(60);
        table_postfix VARCHAR(40);
        create_table    TEXT;
        spec_alter_table TEXT;
        month INTEGER;
        lower TIMESTAMP WITHOUT TIME ZONE;
        upper  TIMESTAMP WITHOUT TIME ZONE;
BEGIN
        table_postfix := quote_ident(partition_postfix(time_begin, service_id, monitoring));
        table_name := 'request_data_' || table_postfix;

        LOCK TABLE request_data IN SHARE UPDATE EXCLUSIVE MODE;

        lower := to_char(date_trunc('month', time_begin), 'YYYY-MM-DD');
        upper := to_char(date_trunc('month', time_begin + interval '1 month'), 'YYYY-MM-DD');

        IF monitoring = true THEN
                create_table  =  'CREATE TABLE ' || table_name || ' (CHECK (request_time_begin >= TIMESTAMP ''' || lower || ''' AND request_time_begin < TIMESTAMP ''' || upper || ''' AND request_monitoring = ''' || bool_to_str(monitoring) || ''') ) INHERITS (request_data) ';   
        ELSE 
                create_table  =  'CREATE TABLE ' || table_name || ' (CHECK (request_time_begin >= TIMESTAMP ''' || lower || ''' AND request_time_begin < TIMESTAMP ''' || upper || ''' AND request_service_id = ' || service_id || ' AND request_monitoring = ''' || bool_to_str(monitoring) || ''') ) INHERITS (request_data) ';
        END IF;
        
        spec_alter_table = 'ALTER TABLE ' || table_name || ' ADD CONSTRAINT ' || table_name || '_entry_id_fkey FOREIGN KEY (request_id) REFERENCES request_' || table_postfix || '(id); ';

        EXECUTE create_table;
        EXECUTE spec_alter_table;
        
        PERFORM create_indexes_request_data(table_name);

EXCEPTION
    WHEN duplicate_table THEN
        NULL;
END;
$create_tbl_request_data$ LANGUAGE plpgsql;

-- CREATE index on content removed (too large rows)
/** parameter table_name must already be processed by quote_ident
*/
CREATE OR REPLACE FUNCTION create_indexes_request_data(table_name VARCHAR(50)) RETURNS VOID AS $create_indexes_request_data$
DECLARE 
        create_indexes TEXT;
BEGIN
        create_indexes = 'CREATE INDEX ' || table_name || '_entry_time_begin_idx ON ' || table_name || '(request_time_begin); CREATE INDEX ' || table_name || '_entry_id_idx ON ' || table_name || '(request_id); CREATE INDEX ' || table_name || '_is_response_idx ON ' || table_name || '(is_response);';
        EXECUTE create_indexes;
END;
$create_indexes_request_data$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_tbl_request_property_value(time_begin TIMESTAMP WITHOUT TIME ZONE, service_id INTEGER, monitoring BOOLEAN) RETURNS VOID AS $create_tbl_request_property_value$
DECLARE 
        table_name VARCHAR(60);
        table_postfix VARCHAR (40);
        create_table    TEXT;
        spec_alter_table TEXT;
        month INTEGER;
        lower TIMESTAMP WITHOUT TIME ZONE;
        upper  TIMESTAMP WITHOUT TIME ZONE;
BEGIN
        table_postfix := quote_ident(partition_postfix(time_begin, service_id, monitoring));
        table_name := 'request_property_value_' || table_postfix; 

        LOCK TABLE request_property_value IN SHARE UPDATE EXCLUSIVE MODE;

        lower := to_char(date_trunc('month', time_begin), 'YYYY-MM-DD');
        upper := to_char(date_trunc('month', time_begin + interval '1 month'), 'YYYY-MM-DD');

        IF monitoring = true THEN
                create_table  =  'CREATE TABLE ' || table_name || ' (CHECK (request_time_begin >= TIMESTAMP ''' || lower || ''' AND request_time_begin < TIMESTAMP ''' || upper || '''  AND request_monitoring = ''' || bool_to_str(monitoring) || ''') ) INHERITS (request_property_value) ';
        ELSE 
                create_table  =  'CREATE TABLE ' || table_name || ' (CHECK (request_time_begin >= TIMESTAMP ''' || lower || ''' AND request_time_begin < TIMESTAMP ''' || upper || '''  AND request_service_id = ' || service_id || ' AND request_monitoring = ''' || bool_to_str(monitoring) || ''') ) INHERITS (request_property_value) ';
        END IF;         

        spec_alter_table = 'ALTER TABLE ' || table_name || ' ADD PRIMARY KEY (id); ALTER TABLE ' || table_name || ' ADD CONSTRAINT ' || table_name || '_entry_id_fkey FOREIGN KEY (request_id) REFERENCES request_' || table_postfix || '(id); ALTER TABLE ' || table_name || ' ADD CONSTRAINT ' || table_name || '_name_id_fkey FOREIGN KEY (property_name_id) REFERENCES request_property_name(id); ALTER TABLE ' || table_name || ' ADD CONSTRAINT ' || table_name || '_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES ' || table_name || '(id); ';

        EXECUTE create_table;
        EXECUTE spec_alter_table;
        PERFORM create_indexes_request_property_value(table_name);
EXCEPTION
    WHEN duplicate_table THEN
        NULL;

END;
$create_tbl_request_property_value$ LANGUAGE plpgsql;


/** parameter table_name must already be processed by quote_ident
*/
CREATE OR REPLACE FUNCTION create_indexes_request_property_value(table_name VARCHAR(50)) RETURNS VOID AS $create_indexes_request_property_value$
DECLARE 
        create_indexes TEXT;
BEGIN
        create_indexes = 'CREATE INDEX ' || table_name || '_entry_time_begin_idx ON ' || table_name || '(request_time_begin); CREATE INDEX ' || table_name || '_entry_id_idx ON ' || table_name || '(request_id); CREATE INDEX ' || table_name || '_name_id_idx ON ' || table_name || '(property_name_id); CREATE INDEX ' || table_name || '_value_idx ON ' || table_name || '(value); CREATE INDEX ' || table_name || '_output_idx ON ' || table_name || '(output); CREATE INDEX ' || table_name || '_parent_id_idx ON ' || table_name || '(parent_id);';
        EXECUTE create_indexes;

END;
$create_indexes_request_property_value$ LANGUAGE plpgsql;

CREATE OR REPLACE RULE request_insert_function AS ON INSERT TO request DO INSTEAD SELECT tr_request ( NEW.id, NEW.time_begin, NEW.time_end, NEW.source_ip, NEW.service_id, NEW.request_type_id, NEW.session_id, NEW.user_name, NEW.is_monitoring); 

CREATE OR REPLACE RULE request_data_insert_function AS ON INSERT TO request_data DO INSTEAD SELECT tr_request_data ( NEW.request_time_begin, NEW.request_service_id, NEW.request_monitoring, NEW.request_id, NEW.content, NEW.is_response); 

CREATE OR REPLACE RULE request_property_value_insert_function AS ON INSERT TO request_property_value DO INSTEAD SELECT tr_request_property_value ( NEW.request_time_begin, NEW.request_service_id, NEW.request_monitoring, NEW.id, NEW.request_id, NEW.property_name_id, NEW.value, NEW.output, NEW.parent_id);

--
-- #4374
--

ALTER TABLE session RENAME COLUMN name TO user_name;

ALTER TABLE session ADD COLUMN user_id INTEGER;

-- drop rule which executes the trigger
DROP RULE session_insert_function ON session;
ALTER TABLE session DROP COLUMN lang;

CREATE OR REPLACE FUNCTION tr_session(id INTEGER, user_name VARCHAR(255), user_id INTEGER, login_date timestamp, logout_date timestamp) RETURNS VOID AS $tr_session$
DECLARE 
        table_name VARCHAR(50);
        stmt  TEXT;
BEGIN
        table_name := quote_ident('session_' || partition_postfix(login_date, -1, false));
        stmt := 'INSERT INTO ' || table_name || ' (id, user_name, user_id, login_date, logout_date) VALUES (' 
                || COALESCE(id::TEXT, 'NULL')           || ', ' 
                || COALESCE(quote_literal(user_name), 'NULL')                 || ', '
                || COALESCE(user_id::TEXT, 'NULL')                       || ', '
                || COALESCE(quote_literal(login_date), 'NULL')           || ', '
                || COALESCE(quote_literal(logout_date), 'NULL')          

                || ')';

        -- raise notice 'session Generated insert: %', stmt;
        EXECUTE stmt;

EXCEPTION
        WHEN undefined_table THEN
        BEGIN
                PERFORM create_tbl_session(login_date);
        
                EXECUTE stmt;
        END;
END;
$tr_session$ LANGUAGE plpgsql;


/** parameter table_name must already be processed by quote_ident
*/
CREATE OR REPLACE FUNCTION create_indexes_session(table_name VARCHAR(50)) RETURNS VOID AS $create_indexes_session$
DECLARE 
        create_indexes TEXT;
BEGIN
        create_indexes = 'CREATE INDEX ' || table_name || '_name_idx ON ' || table_name || '(user_name); CREATE INDEX ' || table_name || '_user_id_idx ON ' || table_name || '(user_id); CREATE INDEX ' || table_name || '_login_date_idx ON ' || table_name || '(login_date);'; 
        EXECUTE create_indexes;

END;
$create_indexes_session$ LANGUAGE plpgsql;


CREATE OR REPLACE RULE session_insert_function AS ON INSERT TO session
DO INSTEAD SELECT tr_session ( NEW.id, NEW.user_name, NEW.user_id, NEW.login_date, NEW.logout_date); 




ALTER TABLE request_property_name ADD UNIQUE (name);

ALTER TABLE request ADD COLUMN user_id INTEGER;



CREATE OR REPLACE FUNCTION tr_request(id INTEGER, time_begin TIMESTAMP WITHOUT TIME ZONE, time_end TIMESTAMP WITHOUT TIME ZONE, source_ip INET, service_id INTEGER, request_type_id INTEGER, session_id INTEGER, user_name VARCHAR(255), user_id INTEGER, is_monitoring BOOLEAN ) RETURNS VOID AS $tr_request$
DECLARE 
        table_name VARCHAR(50);
        stmt       TEXT;
BEGIN
        table_name = quote_ident('request_' || partition_postfix(time_begin, service_id, is_monitoring));

        stmt := 'INSERT INTO ' || table_name || ' (id, time_begin, time_end, source_ip, service_id, request_type_id, session_id, user_name, user_id, is_monitoring) VALUES (' 
                || COALESCE(id::TEXT, 'NULL')           || ', ' 
                || COALESCE(quote_literal(time_begin), 'NULL')           || ', '
                || COALESCE(quote_literal(time_end), 'NULL')             || ', '
                || COALESCE(quote_literal(host(source_ip)), 'NULL')      || ', '
                || COALESCE(service_id::TEXT, 'NULL')      || ', '
                || COALESCE(request_type_id::TEXT, 'NULL')  || ', '
                || COALESCE(session_id::TEXT, 'NULL')   || ', '
                || COALESCE(quote_literal(user_name), 'NULL')            || ', '
                || COALESCE(user_id::TEXT, 'NULL')                       || ', '
                || '''' || bool_to_str(is_monitoring)   || ''') ';
        
        -- raise notice 'request Generated insert: %', stmt;
        EXECUTE stmt;

EXCEPTION
        WHEN undefined_table THEN
        BEGIN
                PERFORM create_tbl_request(time_begin, service_id, is_monitoring);
        
                EXECUTE stmt;
        END;
END;
$tr_request$ LANGUAGE plpgsql;

/** parameter table_name must already be processed by quote_ident
*/
CREATE OR REPLACE FUNCTION create_indexes_request(table_name VARCHAR(50)) RETURNS VOID AS $create_indexes_request$
DECLARE 
        create_indexes TEXT;
BEGIN
        create_indexes := 'CREATE INDEX ' || table_name || '_time_begin_idx ON ' || table_name || '(time_begin);'
                       || 'CREATE INDEX ' || table_name || '_time_end_idx ON ' || table_name || '(time_end);'
                       || 'CREATE INDEX ' || table_name || '_source_ip_idx ON ' || table_name || '(source_ip);'         
                       || 'CREATE INDEX ' || table_name || '_service_idx ON ' || table_name || '(service_id);'  
                       || 'CREATE INDEX ' || table_name || '_action_type_idx ON ' || table_name || '(request_type_id);' 
                       || 'CREATE INDEX ' || table_name || '_monitoring_idx ON ' || table_name || '(is_monitoring);'
                       || 'CREATE INDEX ' || table_name || '_user_name_idx ON ' || table_name || '(user_name);'
                       || 'CREATE INDEX ' || table_name || '_user_id_idx ON ' || table_name || '(user_id);';
        EXECUTE create_indexes;
END;
$create_indexes_request$ LANGUAGE plpgsql;


CREATE OR REPLACE RULE request_insert_function AS ON INSERT TO request DO INSTEAD SELECT tr_request ( NEW.id, NEW.time_begin, NEW.time_end, NEW.source_ip, NEW.service_id, NEW.request_type_id, NEW.session_id, NEW.user_name, NEW.user_id, NEW.is_monitoring); 

---
--- #4313
--- 
---

CREATE TABLE result_code (
    id SERIAL PRIMARY KEY,
    service_id INTEGER REFERENCES service(id),
    result_code INTEGER NOT NULL,
    name VARCHAR(64) NOT NULL    
);

ALTER TABLE result_code ADD CONSTRAINT result_code_unique_code  UNIQUE (service_id, result_code );
ALTER TABLE result_code ADD CONSTRAINT result_code_unique_name  UNIQUE (service_id, name );

COMMENT ON TABLE result_code IS 'all possible operation result codes';
COMMENT ON COLUMN result_code.id IS 'result_code id';
COMMENT ON COLUMN result_code.service_id IS 'reference to service table. This is needed to distinguish entries with identical result_code values';
COMMENT ON COLUMN result_code.result_code IS 'result code as returned by the specific service, it''s only unique within the service';
COMMENT ON COLUMN result_code.name IS 'short name for error (abbreviation) written in camelcase';


ALTER TABLE request ADD COLUMN result_code_id INTEGER;
ALTER TABLE request ADD FOREIGN KEY (result_code_id) REFERENCES result_code(id); 

COMMENT ON COLUMN request.result_code_id IS 'result code as returned by the specific service, it''s only unique within the service';

-- for CloseRequest result_code_id updates, exception commented out until request.result_code_id optional
CREATE OR REPLACE FUNCTION get_result_code_id( integer, integer) 
RETURNS integer AS $$
DECLARE
    result_code_id INTEGER;
BEGIN

    SELECT id FROM result_code INTO result_code_id
        WHERE service_id=$1 and result_code=$2 ; 

    IF result_code_id is null THEN
        RAISE WARNING 'result_code.id not found for service_id=% and result_code=% ', $1, $2;
    END IF;
    RETURN result_code_id;
END;
$$ LANGUAGE plpgsql;

-- Ticket #4392

CREATE TABLE request_object_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(64)
);

CREATE TABLE request_object_ref (
    id SERIAL PRIMARY KEY, 
    request_time_begin TIMESTAMP NOT NULL,
    request_service_id INTEGER  NOT NULL,                                     
    request_monitoring BOOLEAN NOT NULL,                                      
    request_id INTEGER NOT NULL REFERENCES request(id),                       
    object_type_id INTEGER  NOT NULL REFERENCES request_object_type(id),
    object_id INTEGER NOT NULL
);

CREATE INDEX request_object_ref_id_idx ON request_object_ref(request_id);
CREATE INDEX request_object_ref_time_begin_idx ON request_object_ref(request_time_begin);
CREATE INDEX request_object_ref_service_id_idx ON request_object_ref(request_service_id);
CREATE INDEX request_object_ref_object_type_id_idx ON request_object_ref(object_type_id);
CREATE INDEX request_object_ref_object_id_idx ON request_object_ref(object_id);


-- reuqest_object_ref trigger
CREATE OR REPLACE FUNCTION tr_request_object_ref(id INTEGER, request_time_begin TIMESTAMP WITHOUT TIME ZONE, request_service_id INTEGER, request_monitoring BOOLEAN, request_id INTEGER, object_type_id INTEGER, object_id INTEGER) RETURNS VOID AS $tr_request_object_ref$
DECLARE 
        table_name VARCHAR(50);
        stmt TEXT;
BEGIN
        table_name := quote_ident('request_object_ref_' || partition_postfix(request_time_begin, request_service_id, request_monitoring));
        stmt := 'INSERT INTO ' || table_name || ' (id, request_time_begin, request_service_id, request_monitoring, request_id, object_type_id, object_id) VALUES ('
            || COALESCE(id::TEXT, 'NULL')                       || ', '
            || COALESCE(quote_literal(request_time_begin), 'NULL') || ', '
            || COALESCE(request_service_id::TEXT, 'NULL')       || ', '
            || '''' || bool_to_str(request_monitoring)          || ''', ' 
            || COALESCE(request_id::TEXT, 'NULL')               || ', ' 
            || COALESCE(object_type_id::TEXT, 'NULL')           || ', '
            || COALESCE(object_id::TEXT, 'NULL')                
            || ') ';
    
        raise notice 'generated SQL: %', stmt;
        EXECUTE stmt;
EXCEPTION
        WHEN undefined_table THEN
        BEGIN
                raise notice 'In exception handler..... ';
                PERFORM create_tbl_request_object_ref(request_time_begin, request_service_id, request_monitoring);
                EXECUTE stmt;
        END;
END;
$tr_request_object_ref$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_tbl_request_object_ref(time_begin TIMESTAMP WITHOUT TIME ZONE, service_id INTEGER, monitoring BOOLEAN) RETURNS VOID AS $create_tbl_request_object_ref$
DECLARE 
        table_name VARCHAR(60);
        table_postfix VARCHAR (40);
        create_table    TEXT;
        spec_alter_table TEXT;
        month INTEGER;
        lower TIMESTAMP WITHOUT TIME ZONE;
        upper  TIMESTAMP WITHOUT TIME ZONE;
BEGIN
        table_postfix := quote_ident(partition_postfix(time_begin, service_id, monitoring));
        table_name := 'request_object_ref_' || table_postfix; 

        LOCK TABLE request_property_value IN SHARE UPDATE EXCLUSIVE MODE;

        lower := to_char(date_trunc('month', time_begin), 'YYYY-MM-DD');
        upper := to_char(date_trunc('month', time_begin + interval '1 month'), 'YYYY-MM-DD');

        IF monitoring = true THEN
                create_table  =  'CREATE TABLE ' || table_name || ' (CHECK (request_time_begin >= TIMESTAMP ''' || lower || ''' AND request_time_begin < TIMESTAMP ''' || upper || '''  AND request_monitoring = ''' || bool_to_str(monitoring) || ''') ) INHERITS (request_object_ref) ';
        ELSE 
                create_table  =  'CREATE TABLE ' || table_name || ' (CHECK (request_time_begin >= TIMESTAMP ''' || lower || ''' AND request_time_begin < TIMESTAMP ''' || upper || '''  AND request_service_id = ' || service_id || ' AND request_monitoring = ''' || bool_to_str(monitoring) || ''') ) INHERITS (request_object_ref) ';
        END IF;         

        spec_alter_table = 'ALTER TABLE ' || table_name || ' ADD PRIMARY KEY (id); ALTER TABLE ' || table_name || ' ADD CONSTRAINT ' || table_name || '_entry_id_fkey FOREIGN KEY (request_id) REFERENCES request_' || table_postfix || '(id); ALTER TABLE ' || table_name || ' ADD CONSTRAINT ' || table_name || '_object_type_id_fkey FOREIGN KEY (object_type_id) REFERENCES request_object_type(id); ';

        EXECUTE create_table;
        EXECUTE spec_alter_table;
        PERFORM create_indexes_request_object_ref(table_name);
EXCEPTION
    WHEN duplicate_table THEN
        NULL;

END;
$create_tbl_request_object_ref$ LANGUAGE plpgsql; 


CREATE OR REPLACE FUNCTION create_indexes_request_object_ref(table_name VARCHAR(50)) RETURNS VOID as $create_indexes_request_object_ref$ 
DECLARE
        create_indexes TEXT;
BEGIN
        create_indexes := 
       'CREATE INDEX ' || table_name || '_id_idx ON ' || table_name || '(request_id);'
       || 'CREATE INDEX ' || table_name || '_time_begin_idx ON ' || table_name || '(request_time_begin); '
       || 'CREATE INDEX ' || table_name || '_service_id_idx ON ' || table_name || '(request_service_id);'
       || 'CREATE INDEX ' || table_name || '_object_type_id_idx ON ' || table_name || '(object_type_id);'
       || 'CREATE INDEX ' || table_name || '_object_id_idx ON ' || table_name || '(object_id);';
        EXECUTE create_indexes;
END;
$create_indexes_request_object_ref$ LANGUAGE plpgsql;

CREATE OR REPLACE RULE request_object_ref_insert_function AS ON INSERT TO request_object_ref 
DO INSTEAD SELECT tr_request_object_ref (NEW.id, NEW.request_time_begin, NEW.request_service_id, NEW.request_monitoring, NEW.request_id, NEW.object_type_id, NEW.object_id);

-- CREATE partitions for a specific month
CREATE OR REPLACE FUNCTION create_parts_for_month(part_time TIMESTAMP WITHOUT TIME ZONE) RETURNS VOID AS 
$create_parts_for_month$ DECLARE
        serv INTEGER;
        cur REFCURSOR;
BEGIN

        -- a chance for minor optimization: create_tbl_* needs partitions_postfix 
        --- which can be selected from table service. 
        OPEN cur FOR SELECT id FROM service;
        LOOP
            FETCH cur INTO serv;
            EXIT WHEN NOT FOUND;

            PERFORM create_tbl_request(part_time, serv, false);
            PERFORM create_tbl_request_data(part_time, serv, false);
            PERFORM create_tbl_request_property_value(part_time, serv, false);
            PERFORM create_tbl_request_object_ref(part_time, serv, false);
            
        END LOOP;

        close cur;

        -- monitoring (service type doesn't matter here - specifying 1)
        PERFORM create_tbl_request(part_time, 1, true);
        PERFORM create_tbl_request_data(part_time, 1, true);
        PERFORM create_tbl_request_property_value(part_time, 1, true);
        PERFORM create_tbl_request_object_ref(part_time, 1, true);

        -- now service type -1 for session tables
        PERFORM create_tbl_session(part_time);
            
END;
$create_parts_for_month$ LANGUAGE plpgsql;

ALTER TABLE request_type DROP CONSTRAINT request_type_pkey;

ALTER TABLE request_type ADD PRIMARY KEY (id);

ALTER TABLE request_type ADD UNIQUE(name, service_id);

