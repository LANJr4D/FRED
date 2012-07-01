INSERT INTO service (id, partition_postfix, name) VALUES (6, 'mojeid_', 'MojeID');

-- Intranet functions

-- Important! If you add an item here, do not forget to add a translation in 
--      enum/nicms/base/trunk/apps/nicommon/logger/history_reader.py: request_type_codes

INSERT INTO request_type (id, name, service_id) VALUES (1500, 'OpenIDRequest', 6);
INSERT INTO request_type (id, name, service_id) VALUES (1501, 'Login', 6);
INSERT INTO request_type (id, name, service_id) VALUES (1502, 'Logout', 6);
INSERT INTO request_type (id, name, service_id) VALUES (1504, 'UserChange', 6);
INSERT INTO request_type (id, name, service_id) VALUES (1507, 'PasswordResetRequest', 6);
INSERT INTO request_type (id, name, service_id) VALUES (1509, 'TrustChange', 6);
INSERT INTO request_type (id, name, service_id) VALUES (1511, 'AccountStateChange', 6);
INSERT INTO request_type (id, name, service_id) VALUES (1512, 'AuthChange', 6);

INSERT INTO request_type (id, name, service_id) VALUES (1339, 'MessageDetail', 4);
INSERT INTO request_type (id, name, service_id) VALUES (1340, 'MessageFilter', 4);


SELECT setval('request_type_id_seq', (SELECT MAX(id) FROM request_type));

INSERT INTO result_code (service_id, result_code, name) VALUES (6, 1 , 'Success');
INSERT INTO result_code (service_id, result_code, name) VALUES (6, 2 , 'Fail');
INSERT INTO result_code (service_id, result_code, name) VALUES (6, 3 , 'Error');
INSERT INTO result_code (service_id, result_code, name) VALUES (4, 1 , 'Success');
INSERT INTO result_code (service_id, result_code, name) VALUES (4, 2 , 'Fail');
INSERT INTO result_code (service_id, result_code, name) VALUES (4, 3 , 'Error');---

---
--- #4340
--- 
---

-- mod-whoisd result codes
INSERT INTO result_code (service_id, result_code, name) VALUES (0, 101 , 'NoEntriesFound');
INSERT INTO result_code (service_id, result_code, name) VALUES (0, 107 , 'UsageError');
INSERT INTO result_code (service_id, result_code, name) VALUES (0, 108 , 'InvalidRequest');
INSERT INTO result_code (service_id, result_code, name) VALUES (0, 501 , 'InternalServerError');
INSERT INTO result_code (service_id, result_code, name) VALUES (0, 0 , 'Ok');

---
--- #4354
--- 
---

-- whois result codes
INSERT INTO result_code (service_id, result_code, name) VALUES (1, 0 , 'Ok');
INSERT INTO result_code (service_id, result_code, name) VALUES (1, 1 , 'NotFound');
INSERT INTO result_code (service_id, result_code, name) VALUES (1, 2 , 'Error');

-- public request result code
INSERT INTO result_code (service_id, result_code, name) VALUES (2, 0 , 'Ok');
INSERT INTO result_code (service_id, result_code, name) VALUES (2, 1 , 'Error');

-- Ticket #4392

INSERT INTO request_object_type (id, name) VALUES (1, 'contact');
INSERT INTO request_object_type (id, name) VALUES (2, 'nsset');
INSERT INTO request_object_type (id, name) VALUES (3, 'domain');
INSERT INTO request_object_type (id, name) VALUES (4, 'keyset');
INSERT INTO request_object_type (id, name) VALUES (5, 'registrar');
INSERT INTO request_object_type (id, name) VALUES (6, 'mail');
INSERT INTO request_object_type (id, name) VALUES (7, 'file');
INSERT INTO request_object_type (id, name) VALUES (8, 'publicrequest');
INSERT INTO request_object_type (id, name) VALUES (9, 'invoice');
INSERT INTO request_object_type (id, name) VALUES (10, 'bankstatement');
INSERT INTO request_object_type (id, name) VALUES (11, 'request');
INSERT INTO request_object_type (id, name) VALUES (12, 'message');

ALTER TABLE request_type DROP CONSTRAINT request_type_pkey;

ALTER TABLE request_type ADD PRIMARY KEY (id);

ALTER TABLE request_type ADD UNIQUE(name, service_id);

INSERT INTO result_code (service_id, result_code, name) VALUES (3, 1000, 'CommandCompletedSuccessfully');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 1001, 'CommandCompletedSuccessfullyActionPending');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 1300, 'CommandCompletedSuccessfullyNoMessages');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 1301, 'CommandCompletedSuccessfullyAckToDequeue');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 1500, 'CommandCompletedSuccessfullyEndingSession');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2000, 'UnknownCommand');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2001, 'CommandSyntaxError');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2002, 'CommandUseError');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2003, 'RequiredParameterMissing');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2004, 'ParameterValueRangeError');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2005, 'ParameterValueSyntaxError');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2100, 'UnimplementedProtocolVersion');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2101, 'UnimplementedCommand');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2102, 'UnimplementedOption');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2103, 'UnimplementedExtension');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2104, 'BillingFailure');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2105, 'ObjectIsNotEligibleForRenewal');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2106, 'ObjectIsNotEligibleForTransfer');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2200, 'AuthenticationError');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2201, 'AuthorizationError');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2202, 'InvalidAuthorizationInformation');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2300, 'ObjectPendingTransfer');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2301, 'ObjectNotPendingTransfer');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2302, 'ObjectExists');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2303, 'ObjectDoesNotExist');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2304, 'ObjectStatusProhibitsOperation');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2305, 'ObjectAssociationProhibitsOperation');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2306, 'ParameterValuePolicyError');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2307, 'UnimplementedObjectService');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2308, 'DataManagementPolicyViolation');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2400, 'CommandFailed');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2500, 'CommandFailedServerClosingConnection');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2501, 'AuthenticationErrorServerClosingConnection');
INSERT INTO result_code (service_id, result_code, name) VALUES (3, 2502, 'SessionLimitExceededServerClosingConnection');
