---
--- Ticket #3886 - race condition fix
---
CREATE OR REPLACE FUNCTION create_tbl_request(time_begin TIMESTAMP WITHOUT TIME ZONE, service INTEGER, monitoring BOOLEAN) RETURNS VOID AS $create_tbl_request$
DECLARE 
        table_name VARCHAR(60);
        create_table    TEXT;
        spec_alter_table TEXT;
        month INTEGER;
        lower TIMESTAMP WITHOUT TIME ZONE;
        upper  TIMESTAMP WITHOUT TIME ZONE;

BEGIN
        table_name := quote_ident('request' || '_' || partition_postfix(time_begin, service, monitoring));

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
                || upper || ''' AND service = ' || service || ' AND is_monitoring = ''' || bool_to_str(monitoring) || ''') ) INHERITS (request)';          
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


CREATE OR REPLACE FUNCTION create_tbl_request_data(time_begin TIMESTAMP WITHOUT TIME ZONE, service INTEGER, monitoring BOOLEAN) RETURNS VOID AS $create_tbl_request_data$
DECLARE 
        table_name VARCHAR(60);
        table_postfix VARCHAR(40);
        create_table    TEXT;
        spec_alter_table TEXT;
        month INTEGER;
        lower TIMESTAMP WITHOUT TIME ZONE;
        upper  TIMESTAMP WITHOUT TIME ZONE;
BEGIN
        table_postfix := quote_ident(partition_postfix(time_begin, service, monitoring));
        table_name := 'request_data_' || table_postfix;

        LOCK TABLE request_data IN SHARE UPDATE EXCLUSIVE MODE;

        lower := to_char(date_trunc('month', time_begin), 'YYYY-MM-DD');
        upper := to_char(date_trunc('month', time_begin + interval '1 month'), 'YYYY-MM-DD');

        IF monitoring = true THEN
                create_table  =  'CREATE TABLE ' || table_name || ' (CHECK (entry_time_begin >= TIMESTAMP ''' || lower || ''' AND entry_time_begin < TIMESTAMP ''' || upper || ''' AND entry_monitoring = ''' || bool_to_str(monitoring) || ''') ) INHERITS (request_data) ';   
        ELSE 
                create_table  =  'CREATE TABLE ' || table_name || ' (CHECK (entry_time_begin >= TIMESTAMP ''' || lower || ''' AND entry_time_begin < TIMESTAMP ''' || upper || ''' AND entry_service = ' || service || ' AND entry_monitoring = ''' || bool_to_str(monitoring) || ''') ) INHERITS (request_data) ';
        END IF;
        
        spec_alter_table = 'ALTER TABLE ' || table_name || ' ADD CONSTRAINT ' || table_name || '_entry_id_fkey FOREIGN KEY (entry_id) REFERENCES request_' || table_postfix || '(id); ';

        EXECUTE create_table;
        EXECUTE spec_alter_table;
        
        PERFORM create_indexes_request_data(table_name);

EXCEPTION
    WHEN duplicate_table THEN
        NULL;
END;
$create_tbl_request_data$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_tbl_request_property_value(time_begin TIMESTAMP WITHOUT TIME ZONE, service INTEGER, monitoring BOOLEAN) RETURNS VOID AS $create_tbl_request_property_value$
DECLARE 
        table_name VARCHAR(60);
        table_postfix VARCHAR (40);
        create_table    TEXT;
        spec_alter_table TEXT;
        month INTEGER;
        lower TIMESTAMP WITHOUT TIME ZONE;
        upper  TIMESTAMP WITHOUT TIME ZONE;
BEGIN
        table_postfix := quote_ident(partition_postfix(time_begin, service, monitoring));
        table_name := 'request_property_value_' || table_postfix; 

        LOCK TABLE request_property_value IN SHARE UPDATE EXCLUSIVE MODE;

        lower := to_char(date_trunc('month', time_begin), 'YYYY-MM-DD');
        upper := to_char(date_trunc('month', time_begin + interval '1 month'), 'YYYY-MM-DD');

        IF monitoring = true THEN
                create_table  =  'CREATE TABLE ' || table_name || ' (CHECK (entry_time_begin >= TIMESTAMP ''' || lower || ''' AND entry_time_begin < TIMESTAMP ''' || upper || '''  AND entry_monitoring = ''' || bool_to_str(monitoring) || ''') ) INHERITS (request_property_value) ';
        ELSE 
                create_table  =  'CREATE TABLE ' || table_name || ' (CHECK (entry_time_begin >= TIMESTAMP ''' || lower || ''' AND entry_time_begin < TIMESTAMP ''' || upper || '''  AND entry_service = ' || service || ' AND entry_monitoring = ''' || bool_to_str(monitoring) || ''') ) INHERITS (request_property_value) ';
        END IF;         

        spec_alter_table = 'ALTER TABLE ' || table_name || ' ADD PRIMARY KEY (id); ALTER TABLE ' || table_name || ' ADD CONSTRAINT ' || table_name || '_entry_id_fkey FOREIGN KEY (entry_id) REFERENCES request_' || table_postfix || '(id); ALTER TABLE ' || table_name || ' ADD CONSTRAINT ' || table_name || '_name_id_fkey FOREIGN KEY (name_id) REFERENCES request_property(id); ALTER TABLE ' || table_name || ' ADD CONSTRAINT ' || table_name || '_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES ' || table_name || '(id); ';

        EXECUTE create_table;
        EXECUTE spec_alter_table;
        PERFORM create_indexes_request_property_value(table_name);
EXCEPTION
    WHEN duplicate_table THEN
        NULL;

END;
$create_tbl_request_property_value$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION create_tbl_session(time_begin TIMESTAMP WITHOUT TIME ZONE) RETURNS VOID AS $create_tbl_session$
DECLARE 
        table_name VARCHAR(60);
        create_table    TEXT;
        spec_alter_table TEXT;
        month INTEGER;
        lower TIMESTAMP WITHOUT TIME ZONE;
        upper  TIMESTAMP WITHOUT TIME ZONE;

BEGIN
        table_name := quote_ident('session_' || partition_postfix(time_begin, -1, false));

        LOCK TABLE session IN SHARE UPDATE EXCLUSIVE MODE;

        lower := to_char(date_trunc('month', time_begin), 'YYYY-MM-DD');
        upper := to_char(date_trunc('month', time_begin + interval '1 month'), 'YYYY-MM-DD');

        create_table =  'CREATE TABLE ' || table_name || '    (CHECK (login_date >= TIMESTAMP ''' || lower || ''' AND login_date < TIMESTAMP ''' || upper || ''') ) INHERITS (session) ';

        spec_alter_table = 'ALTER TABLE ' || table_name || ' ADD PRIMARY KEY (id); ';


        EXECUTE create_table;
        EXECUTE spec_alter_table;

        PERFORM create_indexes_session(table_name);

EXCEPTION
    WHEN duplicate_table THEN
        NULL;
END;
$create_tbl_session$ LANGUAGE plpgsql;

