--- update version
UPDATE enum_parameters SET val='2.1.0.1' WHERE id=1;


ALTER TABLE check_test DROP COLUMN need_domain;
ALTER TABLE check_test ADD COLUMN need_domain SMALLINT NOT NULL DEFAULT 0;
UPDATE check_test SET need_domain = 1 WHERE
        name = 'presence' OR
        name = 'authoritative';
UPDATE check_test SET need_domain = 2 WHERE
        name = 'existence' OR
        name = 'glue_ok' OR
        name = 'notrecursive';

ALTER TABLE ONLY public_request_objects_map
    ADD CONSTRAINT public_request_objects_map_pkey PRIMARY KEY (request_id);

ALTER TABLE ONLY poll_credit_zone_limit
    ADD CONSTRAINT poll_credit_zone_limit_pkey PRIMARY KEY (zone);

ALTER TABLE bank_account DROP CONSTRAINT bank_account_account_number_key;

CREATE INDEX action_enddate_idx_date ON action USING btree (((enddate)::date));

comment on table Contact_History is
'Historic data from contact table.
creation - actual data will be copied here from original table in case of any change in contact table';

COMMENT ON TABLE history IS 'Main evidence table with modified data, it join historic tables modified during same operation
create - in case of any change';

COMMENT ON COLUMN dnskey.alg IS 'used algorithm (see http://rfc-ref.org/RFC-TEXTS/4034/chapter11.html for further details)';

COMMENT ON TABLE enum_error IS 'Table of error messages
id   - message
1000 - command completed successfully
1001 - command completed successfully, action pending
1300 - command completed successfully, no messages
1301 - command completed successfully, act to dequeue
1500 - command completed successfully, ending session
2000 - unknown command
2001 - command syntax error
2002 - command use error
2003 - required parameter missing
2004 - parameter value range error
2005 - parameter value systax error
2100 - unimplemented protocol version
2101 - unimplemented command
2102 - unimplemented option
2103 - unimplemented extension
2104 - billing failure
2105 - object is not eligible for renewal
2106 - object is not eligible for transfer
2200 - authentication error
2201 - authorization error
2202 - invalid authorization information
2300 - object pending transfer
2301 - object not pending transfer
2302 - object exists
2303 - object does not exists
2304 - object status prohibits operation
2305 - object association prohibits operation
2306 - parameter value policy error
2307 - unimplemented object service
2308 - data management policy violation
2400 - command failed
2500 - command failed, server closing connection
2501 - authentication error, server closing connection
2502 - session limit exceeded, server closing connection';
