UPDATE enum_parameters SET val='1.8.1' WHERE id=1;

DROP INDEX action_elements_elementid_idx;
CREATE INDEX action_elements_actionid_idx ON action_elements (actionid);

CREATE INDEX domain_exdate_idx ON domain (exdate);
CREATE INDEX action_clienttrid_idx ON action (clienttrid);
CREATE INDEX object_state_object_id_all_idx ON object_state (object_id);

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--    Comments go into database
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

COMMENT ON TABLE enum_country is 'list of country codes and names';
COMMENT ON COLUMN enum_country.id is 'country code (e.g. CZ for Czech republic)';
COMMENT ON COLUMN enum_country.country is 'english country name';
COMMENT ON COLUMN enum_country.country_cs is 'optional country name in native language';
COMMENT ON COLUMN domain_blacklist.regexp is 'regular expression which is blocked';
COMMENT ON COLUMN domain_blacklist.valid_from is 'from when is block valid';
COMMENT ON COLUMN domain_blacklist.valid_to is 'till when is block valid, if it is NULL, it is not restricted';
COMMENT ON COLUMN domain_blacklist.reason is 'reason why is domain blocked';
COMMENT ON COLUMN domain_blacklist.creator is 'who created this record. If it is NULL, it is system record created as a part of system configuration';
COMMENT ON TABLE enum_bank_code is 'list of bank codes';
COMMENT ON COLUMN enum_bank_code.code is 'bank code';
COMMENT ON COLUMN enum_bank_code.name_short is 'bank name abbrevation';
COMMENT ON COLUMN enum_bank_code.name_full is 'full bank name';
COMMENT ON TABLE enum_ssntype is
'Table of identification number types

types:
id - type   - description
 1 - RC     - born number
 2 - OP     - identity card number
 3 - PASS   - passport number
 4 - ICO    - organization identification number
 5 - MPSV   - social system identification
 6 - BIRTHDAY - day of birth';
COMMENT ON COLUMN enum_ssntype.type is 'type abbrevation';
COMMENT ON COLUMN enum_ssntype.description is 'type description';
COMMENT ON TABLE enum_tlds is 'list of available tlds for checking of dns host tld';
COMMENT ON COLUMN invoice_prefix.Zone is 'reference to zone';
COMMENT ON COLUMN invoice_prefix.typ is 'invoice type (0-advanced, 1-normal)';
COMMENT ON COLUMN invoice_prefix.year is 'for which year';
COMMENT ON COLUMN invoice_prefix.prefix is 'counter with prefix of number of invoice';
COMMENT ON TABLE invoice is 'table of invoices';
COMMENT ON COLUMN invoice.id is 'unique automatically generated identifier';
COMMENT ON COLUMN invoice.Zone is 'reference to zone';
COMMENT ON COLUMN invoice.CrDate is 'date and time of invoice creation';
COMMENT ON COLUMN invoice.TaxDate is 'date of taxable fulfilment (when payment cames by advance FA)';
COMMENT ON COLUMN invoice.prefix is '9 placed number of invoice from invoice_prefix.prefix counted via TaxDate';
COMMENT ON COLUMN invoice.registrarID is 'link to registrar';
COMMENT ON COLUMN invoice.Credit is 'credit from which is taken till zero, if it is NULL it is normal invoice';
COMMENT ON COLUMN invoice.Price is 'invoice high with tax';
COMMENT ON COLUMN invoice.VAT is 'VAT hight from account';
COMMENT ON COLUMN invoice.total is 'amount without tax';
COMMENT ON COLUMN invoice.totalVAT is 'tax paid';
COMMENT ON COLUMN invoice.prefix_type is 'invoice type (from which year is and which type is according to prefix)';
COMMENT ON COLUMN invoice.file is 'link to generated PDF file, it can be NULL till file is generated';
COMMENT ON COLUMN invoice.fileXML is 'link to generated XML file, it can be NULL till file is generated';
COMMENT ON COLUMN invoice_generation.id is 'unique automatically generated identifier';
COMMENT ON COLUMN invoice_generation.InvoiceID is 'id of normal invoice';
COMMENT ON COLUMN invoice_credit_payment_map.invoiceID is 'id of normal invoice';
COMMENT ON COLUMN invoice_credit_payment_map.ainvoiceID is 'id of advance invoice';
COMMENT ON COLUMN invoice_credit_payment_map.credit is 'seized credit';
COMMENT ON COLUMN invoice_credit_payment_map.balance is 'actual tax balance advance invoice';
COMMENT ON COLUMN invoice_object_registry.id is 'unique automatically generated identifier';
COMMENT ON COLUMN invoice_object_registry.invoiceID is 'id of invoice for which is item counted';
COMMENT ON COLUMN invoice_object_registry.CrDate is 'billing date and time';
COMMENT ON COLUMN invoice_object_registry.zone is 'link to zone';
COMMENT ON COLUMN invoice_object_registry.registrarID is 'link to registrar';
COMMENT ON COLUMN invoice_object_registry.operation is 'operation type of registration or renew';
COMMENT ON COLUMN invoice_object_registry.ExDate is 'final ExDate only for RENEW';
COMMENT ON COLUMN invoice_object_registry.period is 'number of unit for renew in months';
COMMENT ON COLUMN invoice_object_registry_price_map.InvoiceID is 'id of advanced invoice';
COMMENT ON COLUMN invoice_object_registry_price_map.price is 'operation cost';
COMMENT ON COLUMN invoice_mails.invoiceid is 'link to invoices';
COMMENT ON COLUMN invoice_mails.mailid is 'e-mail which contains this invoice';
COMMENT ON TABLE Contact_History is
'Historic data from contact table.
creation - actual data will be copied here from original table in case of any change in contact table';
COMMENT ON TABLE Domain_History is
'Historic data from domain table

creation - in case of any change in domain table, including changes in bindings to other tables';
COMMENT ON TABLE domain_contact_map_history is
'Historic data from domain_contact_map table

creation - all contacts links which are linked to changed domain are copied here';
COMMENT ON TABLE NSSet_History is
'Historic data from domain nsset

creation - in case of any change in nsset table, including changes in bindings to other tables';
COMMENT ON TABLE nsset_contact_map_history is
'Historic data from nsset_contact_map table

creation - all contact links which are linked to changed nsset are copied here';
COMMENT ON TABLE Host_history is
'historic data from host table

creation - all entries from host table which exist for given nsset are copied here when nsset is altering';
COMMENT ON TABLE Registrar is 'Evidence of registrars, who can create or change administered object via register';
COMMENT ON COLUMN Registrar.ID is 'unique automatically generated identifier';
COMMENT ON COLUMN Registrar.ICO is 'organization identification number';
COMMENT ON COLUMN Registrar.DIC is 'tax identification number';
COMMENT ON COLUMN Registrar.varsymb is 'coupling variable symbol (ico)';
COMMENT ON COLUMN Registrar.VAT is 'whether VAT should be count in invoicing';
COMMENT ON COLUMN Registrar.Handle is 'unique text string identifying registrar, it is generated by system admin when new registrar is created';
COMMENT ON COLUMN Registrar.Name is 'registrats name';
COMMENT ON COLUMN Registrar.Organization is 'Official company name';
COMMENT ON COLUMN Registrar.Street1 is 'part of address';
COMMENT ON COLUMN Registrar.Street2 is 'part of address';
COMMENT ON COLUMN Registrar.Street3 is 'part of address';
COMMENT ON COLUMN Registrar.City is 'part of address - city';
COMMENT ON COLUMN Registrar.StateOrProvince is 'part of address - region';
COMMENT ON COLUMN Registrar.PostalCode is 'part of address - postal code';
COMMENT ON COLUMN Registrar.Country is 'code for country from enum_country table';
COMMENT ON COLUMN Registrar.Telephone is 'phone number';
COMMENT ON COLUMN Registrar.Fax is 'fax number';
COMMENT ON COLUMN Registrar.Email is 'e-mail address';
COMMENT ON COLUMN Registrar.Url is 'registrars web address';
COMMENT ON TABLE RegistrarACL is 'Registrars login information';
COMMENT ON COLUMN RegistrarACL.Cert is 'certificate fingerprint';
COMMENT ON COLUMN RegistrarACL.Password is 'login password';
COMMENT ON COLUMN RegistrarInvoice.Zone is 'zone for which has registrar an access';
COMMENT ON COLUMN RegistrarInvoice.FromDate is 'date when began registrar work in a zone';
COMMENT ON COLUMN RegistrarInvoice.LastDate is 'date when was last created an invoice';
COMMENT ON TABLE MessageType is
'table with message number codes and its names

id - name
01 - credit
02 - techcheck
03 - transfer_contact
04 - transfer_nsset
05 - transfer_domain
06 - delete_contact
07 - delete_nsset
08 - delete_domain
09 - imp_expiration
10 - expiration
11 - imp_validation
12 - validation
13 - outzone';
COMMENT ON TABLE Message is 'Evidence of messages for registrars, which can be picked up by epp poll funcion';
COMMENT ON TABLE enum_status is
'id - status
1   - ok
2   - inactive
101 - clientDeleteProhibited
201 - serverDeleteProhibited
102 - clientHold
202 - serverHold
103 - clientRenewProhibited
203 - serverRenewProhibited
104 - clientTransferProhibited
204 - serverTransferProhibited
105 - clientUpdateProhibited
205 - serverUpdateProhibited
301 - pendingCreate
302 - pendingDelete
303 - pendingRenew
304 - pendingTransfer
305 - pendingUpdate';
COMMENT ON COLUMN enum_status.id is 'status id';
COMMENT ON COLUMN enum_status.status is 'status message';
COMMENT ON TABLE mail_defaults is 
'Defaults used in templates which change rarely.
Default names must be prefixed with ''defaults'' namespace when used in template';
COMMENT ON COLUMN mail_defaults.name is 'key of default';
COMMENT ON COLUMN mail_defaults.value is 'value of default';
COMMENT ON TABLE mail_footer is 'Mail footer is defided in this table and not in templates in order to reduce templates size';
COMMENT ON TABLE mail_vcard is 'vcard is attached to every email message';
COMMENT ON TABLE mail_header_defaults is
'Some header defaults which are likely not a subject to change are specified in database and used in absence';
COMMENT ON COLUMN mail_header_defaults.h_from is '''From:'' header';
COMMENT ON COLUMN mail_header_defaults.h_replyto is '''Reply-to:'' header';
COMMENT ON COLUMN mail_header_defaults.h_errorsto is '''Errors-to:'' header';
COMMENT ON COLUMN mail_header_defaults.h_organization is '''Organization:'' header';
COMMENT ON COLUMN mail_header_defaults.h_contentencoding is '''Content-encoding:'' header';
COMMENT ON COLUMN mail_header_defaults.h_messageidserver is 'Message id cannot be overriden by client, in db is stored only part after ''@'' character';
COMMENT ON TABLE mail_templates is 'Here are stored email templates which represent one text attachment of email message';
COMMENT ON COLUMN mail_templates.contenttype is 'subtype of content type text';
COMMENT ON COLUMN mail_templates.template is 'clearsilver template';
COMMENT ON COLUMN mail_templates.footer is 'should footer be concatenated with template?';
COMMENT ON TABLE mail_type is 'Type of email gathers templates from which email is composed';
COMMENT ON COLUMN mail_type.name is 'name of type';
COMMENT ON COLUMN mail_type.subject is 'template of email subject';
COMMENT ON TABLE mail_archive is
'Here are stored emails which are going to be sent and email which have
already been sent (they differ in status value).';
COMMENT ON COLUMN mail_archive.mailtype is 'email type';
COMMENT ON COLUMN mail_archive.crdate is 'date and time of insertion in table';
COMMENT ON COLUMN mail_archive.moddate is 'date and time of sending (event unsuccesfull)';
COMMENT ON COLUMN mail_archive.status is 
'status value has following meanings:
 0 - the email was successfully sent
 1 - the email is ready to be sent
 x - the email wait for manual confirmation which should change status value to 0
     when the email is desired to be sent. x represent any value different from
     0 and 1 (convention is number 2)';
COMMENT ON COLUMN mail_archive.message is 'text of email which is asssumed to be notificaion about undelivered';
COMMENT ON COLUMN mail_archive.attempt is 
'failed attempt to send email message to be sent including headers
(except date and msgid header), without non-templated attachments';
COMMENT ON TABLE mail_attachments is 'list of attachment ids bound to email in mail_archive';
COMMENT ON COLUMN mail_attachments.mailid is 'id of email in archive';
COMMENT ON COLUMN mail_attachments.attachid is 'attachment id';
COMMENT ON TABLE mail_handles is 'handles associated with email in mail_archive';
COMMENT ON COLUMN mail_handles.mailid is 'id of email in archive';
COMMENT ON COLUMN mail_handles.associd is 'handle of associated object';
COMMENT ON TABLE enum_reason is 'Table of error messages reason';
COMMENT ON COLUMN enum_reason.reason is 'reason in english language';
COMMENT ON COLUMN enum_reason.reason_cs is 'reason in native language';
COMMENT ON TABLE enum_action IS 
'List of action which can be done using epp communication over central registry

id  - status
100 - ClientLogin
101 - ClientLogin
120 - PollAcknowledgement
121 - PollResponse
200 - ContactCheck
201 - ContactInfo
202 - ContactDelete
203 - ContactUpdate
204 - ContactCreate
205 - ContactTransfer
400 - NSsetCheck
401 - NSsetInfo
402 - NSsetDelete
403 - NSsetUpdate
404 - NSsetCreate
405 - NSsetTransfer
500 - DomainCheck
501 - DomainInfo
502 - DomainDelete
503 - DomainUpdate
504 - DomainCreate
505 - DomainTransfer
506 - DomainRenew
507 - DomainTrade
1000 - UnknownAction
1002 - ListContact
1004 - ListNSset
1005 - ListDomain
1010 - ClientCredit
1012 - nssetTest
1101 - ContactSendAuthInfo
1102 - NSSetSendAuthInfo
1103 - DomainSendAuthInfo
1104 - Info
1105 - GetInfoResults';
COMMENT ON TABLE action is 
'Table for transactions record. In this table is logged every operation done over central register

creation - at the beginning of processing any epp message
update - at the end of processing any epp message';
COMMENT ON COLUMN action.id is 'unique automatically generated identifier';
COMMENT ON COLUMN action.clientid is 'id of client from table Login, it is possible have null value here';
COMMENT ON COLUMN action.action is 'type of function(action) from classifier';
COMMENT ON COLUMN action.response is 'return code of function';
COMMENT ON COLUMN action.StartDate is 'date and time when function starts';
COMMENT ON COLUMN action.EndDate is 'date and time when function ends';
COMMENT ON COLUMN action.clientTRID is 'client transaction identifier, client must care about its unique, server copy it to response';
COMMENT ON COLUMN action.serverTRID is 'server transaction identifier';
COMMENT ON TABLE history is
'Main evidence table with modified data, it join historic tables modified during same operation
create - in case of any change';
COMMENT ON COLUMN history.id is 'unique automatically generated identifier';
COMMENT ON COLUMN history.action is 'link to action which cause modification';
COMMENT ON TABLE notify_statechange_map is
'Notification processing rules - direct notifier what mails need to be send
and whom upon object state change';
COMMENT ON TABLE notify_statechange is 'store information about successfull notification';
COMMENT ON COLUMN notify_statechange.state_id is 'which statechnage triggered notification';
COMMENT ON COLUMN notify_statechange.type is 'what notification was done';
COMMENT ON COLUMN notify_statechange.mail_id is 'email with result of notification (null if contact have no email)';
COMMENT ON TABLE notify_letters is 'notification about deleteWarning state by PDF letter, multiple states is stored in one PDF document';
COMMENT ON COLUMN notify_letters.state_id is 'which statechange triggered notification';
COMMENT ON COLUMN notify_letters.file_id is 'file with pdf about notification (null for old)';
COMMENT ON COLUMN OBJECT_registry.ID is 'unique automatically generated identifier';
COMMENT ON COLUMN OBJECT_registry.ROID is 'unique roid';
COMMENT ON COLUMN OBJECT_registry.type is 'object type (1-contact, 2-nsset, 3-domain)';
COMMENT ON COLUMN OBJECT_registry.name is 'handle of fqdn';
COMMENT ON COLUMN OBJECT_registry.CrID is 'link to registrar';
COMMENT ON COLUMN OBJECT_registry.CrDate is 'object creation date and time';
COMMENT ON COLUMN OBJECT_registry.ErDate is 'object erase date';
COMMENT ON COLUMN OBJECT_registry.CrhistoryID is 'link into create history';
COMMENT ON COLUMN OBJECT_registry.historyID is 'link to last change in history';
COMMENT ON TABLE Contact is 'List of contacts which act in register as domain owners and administrative contacts for nameservers group';
COMMENT ON COLUMN Contact.ID is 'references into object table';
COMMENT ON COLUMN Contact.Name is 'name of contact person';
COMMENT ON COLUMN Contact.Organization is 'full trade name of organization';
COMMENT ON COLUMN Contact.Street1 is 'part of address';
COMMENT ON COLUMN Contact.Street2 is 'part of address';
COMMENT ON COLUMN Contact.Street3 is 'part of address';
COMMENT ON COLUMN Contact.City is 'part of address - city';
COMMENT ON COLUMN Contact.StateOrProvince is 'part of address - region';
COMMENT ON COLUMN Contact.PostalCode is 'part of address - postal code';
COMMENT ON COLUMN Contact.Country is 'two character country code (e.g. cz) from enum_country table';
COMMENT ON COLUMN Contact.Telephone is 'telephone number';
COMMENT ON COLUMN Contact.Fax is 'fax number';
COMMENT ON COLUMN Contact.Email is 'email address';
COMMENT ON COLUMN Contact.DiscloseName is 'whether reveal contact name';
COMMENT ON COLUMN contact.DiscloseOrganization is 'whether reveal organization';
COMMENT ON COLUMN Contact.DiscloseAddress is 'whether reveal address';
COMMENT ON COLUMN Contact.DiscloseTelephone is 'whether reveal phone number';
COMMENT ON COLUMN Contact.DiscloseFax is 'whether reveal fax number';
COMMENT ON COLUMN Contact.DiscloseEmail is 'whether reveal email address';
COMMENT ON COLUMN Contact.NotifyEmail is 'to this email address will be send message in case of any change in domain or nsset affecting contact';
COMMENT ON COLUMN Contact.VAT is 'tax number';
COMMENT ON COLUMN Contact.SSN is 'unambiguous identification number (e.g. Social Security number, identity card number, date of birth)';
COMMENT ON COLUMN Contact.SSNtype is 'type of identification number from enum_ssntype table';
COMMENT ON COLUMN Contact.DiscloseVAT is 'whether reveal VAT number';
COMMENT ON COLUMN Contact.DiscloseIdent is 'whether reveal SSN number';
COMMENT ON COLUMN Contact.DiscloseNotifyEmail is 'whether reveal notify email';
COMMENT ON TABLE Host is 'Records of relationship between nameserver and ip address';
COMMENT ON COLUMN Host.id is 'unique automatically generatet identifier';
COMMENT ON COLUMN Host.NSSetID is 'in which nameserver group belong this record';
COMMENT ON COLUMN Host.FQDN is 'fully qualified domain name that is in zone file as NS';
COMMENT ON TABLE Domain is 'Evidence of domains';
COMMENT ON COLUMN Domain.ID is 'point to object table';
COMMENT ON COLUMN Domain.Zone is 'zone in which domain belong';
COMMENT ON COLUMN Domain.Registrant is 'domain owner';
COMMENT ON COLUMN Domain.NSSet is 'link to nameserver set, can be NULL (when is domain registered withou nsset)';
COMMENT ON COLUMN Domain.Exdate is 'domain expiry date';
COMMENT ON TABLE enum_error is
'Table of error messages
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
COMMENT ON COLUMN enum_error.id is 'id of error';
COMMENT ON COLUMN enum_error.status is 'error message in english language';
COMMENT ON COLUMN enum_error.status_cs is 'error message in native language';
COMMENT ON TABLE genzone_domain_status is
'List of status for domain zone generator classification

id - name
 1 - domain is in zone
 2 - domain is deleted
 3 - domain is without nsset
 4 - domain is expired
 5 - domain is not validated';
COMMENT ON TABLE enum_parameters is
'Table of system operational parameters.
Meanings of parameters:

1 - model version - for checking data model version and for applying upgrade scripts
2 - tld list version - for updating table enum_tlds by data from url
3 - expiration notify period - used to change state of domain to unguarded and remove domain from DNS,
    value is number of days relative to date domain.exdate
4 - expiration dns protection period - same as parameter 3
5 - expiration letter warning period - used to change state of domain to deleteWarning and generate letter
    witch warning
6 - expiration registration protection period - used to change state of domain to deleteCandidate and
    unregister domain from system
7 - validation notify 1 period - used to change state of domain to validationWarning1 and send poll
    message to registrar
8 - validation notify 2 period - used to change state of domain to validationWarning2 and send
    email to registrant
9 - regular day procedure period - used to identify hout when objects are deleted and domains
    are moving outzone
10 - regular day procedure zone - used to identify time zone in which parameter 9 is specified';
COMMENT ON COLUMN enum_parameters.id is 'primary identification';
COMMENT ON COLUMN enum_parameters.name is 'descriptive name of parameter - for information uses only';
COMMENT ON COLUMN enum_parameters.val is 'value of parameter';
COMMENT ON TABLE enum_notify is
'list of notify operations

id - notify - explenation
 1 - domain exDate after - domain is after date of expiration
 2 - domain DNS after - domain is excluded from a zone
 3 - domain DEL - domain is definitively deleted
 4 - domain valexDate before - domain is closely before expiration of validation date
 5 - domain valexDate after - domain is after expiration of validation date
 6 - domain exDate before - domain is closely before expiration of expiration';
COMMENT ON COLUMN object_status_notifications.notify is 'notification type';
COMMENT ON COLUMN object_status_notifications.historyid is 'recording of status, in which some object is';
COMMENT ON COLUMN object_status_notifications.messageid is 'if it is also epp message distributed';
COMMENT ON COLUMN object_status_notifications_mail_map.mail_type is 'type of email notification';
COMMENT ON COLUMN object_status_notifications_mail_map.mailid is 'id of sended e-mail';
COMMENT ON TABLE Login is
'records of all epp session

creating - when processing login epp message
updating - when processing logout epp message';
COMMENT ON COLUMN Login.ID is 'return as cliendID from CORBA Login FUNCTION';
COMMENT ON COLUMN Login.RegistrarID is 'registrar id';
COMMENT ON COLUMN Login.LoginDate is 'login date and time into system';
COMMENT ON COLUMN Login.loginTRID is 'login transaction number';
COMMENT ON COLUMN Login.LogoutDate is 'logout date and time';
COMMENT ON COLUMN Login.logoutTRID is 'logout transaction number';
COMMENT ON COLUMN Login.lang is 'language, in which return error messages';
COMMENT ON TABLE enum_filetype is 'list of file types

id - name
 1 - invoice pdf
 2 - invoice xml
 3 - accounting xml
 4 - banking statement
 5 - expiration warning letter';
COMMENT ON TABLE files is 'table of files';
COMMENT ON COLUMN files.id is 'unique automatically generated identifier';
COMMENT ON COLUMN files.name is 'file name';
COMMENT ON COLUMN files.path is 'path to file';
COMMENT ON COLUMN files.mimetype is 'file mimetype';
COMMENT ON COLUMN files.crdate is 'file creation timestamp';
COMMENT ON COLUMN files.filesize is 'file size';
COMMENT ON COLUMN files.filetype is 'file type from table enum_filetype';
COMMENT ON TABLE enum_operation is 'list of priced operation';
COMMENT ON COLUMN enum_operation.id is 'unique automatically generated identifier';
COMMENT ON COLUMN enum_operation.operation is 'operation';
COMMENT ON TABLE price_vat is 'Table of VAT validity (in case that VAT is changing in the future. Stores coefficient for VAT recount)';
COMMENT ON COLUMN price_vat.id is 'unique automatically generated identifier';
COMMENT ON COLUMN price_vat.valid_to is 'date of VAT change realization';
COMMENT ON COLUMN price_vat.koef is 'coefficient high for VAT recount';
COMMENT ON COLUMN price_vat.VAT is 'VAT high';
COMMENT ON TABLE price_list is 'list of operation prices';
COMMENT ON COLUMN price_list.id is 'unique automatically generated identifier';
COMMENT ON COLUMN price_list.zone is 'link to zone, for which is price list valid if it is domain (if it is not domain then it is NULL)';
COMMENT ON COLUMN price_list.operation is 'for which action is price connected';
COMMENT ON COLUMN price_list.valid_from is 'from when is record valid';
COMMENT ON COLUMN price_list.valid_to is 'till when is record valid, if it is NULL then valid is unlimited';
COMMENT ON COLUMN price_list.price is 'cost of operation (for one year-12 months)';
COMMENT ON COLUMN price_list.period is 'period (in months) of payment, null if it is not periodic';
COMMENT ON TABLE bank_account is
'This table contains information about register administrator bank account';
COMMENT ON COLUMN bank_account.id is 'unique automatically generated identifier';
COMMENT ON COLUMN bank_account.zone is 'for which zone should be account executed';
COMMENT ON COLUMN bank_account.balance is 'actual balance';
COMMENT ON COLUMN bank_account.last_date is 'date of last statement';
COMMENT ON COLUMN bank_account.last_num is 'number of last statement';
COMMENT ON COLUMN BANK_STATEMENT_HEAD.id is 'unique automatically generated identifier';
COMMENT ON COLUMN BANK_STATEMENT_HEAD.account_id is 'link to used bank account';
COMMENT ON COLUMN BANK_STATEMENT_HEAD.num is 'statements number';
COMMENT ON COLUMN BANK_STATEMENT_HEAD.create_date is 'statement creation date';
COMMENT ON COLUMN BANK_STATEMENT_HEAD.balance_old is 'old balance state';
COMMENT ON COLUMN BANK_STATEMENT_HEAD.balance_credit is 'income during statement';
COMMENT ON COLUMN BANK_STATEMENT_HEAD.balance_debet is 'expenses during statement';
COMMENT ON COLUMN BANK_STATEMENT_ITEM.id is 'unique automatically generated identifier';
COMMENT ON COLUMN BANK_STATEMENT_ITEM.statement_id is 'link to statement head';
COMMENT ON COLUMN BANK_STATEMENT_ITEM.account_number is 'contra-account number from which came or was sent a payment';
COMMENT ON COLUMN BANK_STATEMENT_ITEM.bank_code is 'contra-account bank code';
COMMENT ON COLUMN BANK_STATEMENT_ITEM.code is 'operation code (1-debet item, 2-credit item, 4-cancel debet, 5-cancel credit)';
COMMENT ON COLUMN BANK_STATEMENT_ITEM.KonstSym is 'constant symbol (contains bank code too)';
COMMENT ON COLUMN BANK_STATEMENT_ITEM.VarSymb is 'variable symbol';
COMMENT ON COLUMN BANK_STATEMENT_ITEM.SpecSymb is 'spec symbol';
COMMENT ON COLUMN BANK_STATEMENT_ITEM.price is 'applied positive(credit) or negative(debet) amount';
COMMENT ON COLUMN BANK_STATEMENT_ITEM.account_evid is 'account evidence';
COMMENT ON COLUMN BANK_STATEMENT_ITEM.account_date is 'accounting date';
COMMENT ON COLUMN BANK_STATEMENT_ITEM.account_memo is 'note';
COMMENT ON COLUMN BANK_STATEMENT_ITEM.invoice_ID is 'null if it is not income payment of process otherwise link to proper invoice';
COMMENT ON TABLE BANK_EBANKA_LIST is 'items of online e-banka statement';
COMMENT ON COLUMN BANK_EBANKA_LIST.id is 'unique automatically generated identificator';
COMMENT ON COLUMN BANK_EBANKA_LIST.account_id is 'link to current account';
COMMENT ON COLUMN BANK_EBANKA_LIST.price is 'transfer amount';
COMMENT ON COLUMN BANK_EBANKA_LIST.CrDate is 'date and time of transfer in UTC';
COMMENT ON COLUMN BANK_EBANKA_LIST.account_number is 'contra-account number';
COMMENT ON COLUMN BANK_EBANKA_LIST.bank_code is 'bank code';
COMMENT ON COLUMN BANK_EBANKA_LIST.KonstSym is 'constant symbol of payment';
COMMENT ON COLUMN BANK_EBANKA_LIST.VarSymb is 'variable symbol of payment';
COMMENT ON COLUMN BANK_EBANKA_LIST.memo is 'note';
COMMENT ON COLUMN BANK_EBANKA_LIST.name is 'account name from which came a payment';
COMMENT ON COLUMN BANK_EBANKA_LIST.Ident is 'unique identifier of payment';
COMMENT ON COLUMN BANK_EBANKA_LIST.invoice_ID is 'null if it is not income payement process otherwise link to proper invoice';
COMMENT ON TABLE enum_object_states is 'list of all supported status types';
COMMENT ON COLUMN enum_object_states.name is 'code name for status';
COMMENT ON COLUMN enum_object_states.types is 'what types of objects can have this status (object_registry.type list)';
COMMENT ON COLUMN enum_object_states.manual is 'if this status is set manualy';
COMMENT ON COLUMN enum_object_states.external is 'if this status is exported to public';
COMMENT ON TABLE enum_object_states_desc is 'description for states in different languages';
COMMENT ON COLUMN enum_object_states_desc.lang is 'code of language';
COMMENT ON COLUMN enum_object_states_desc.description is 'descriptive text';
COMMENT ON TABLE object_state is 'main table of object states and their changes';
COMMENT ON COLUMN object_state.object_id is 'id of object that has this new status';
COMMENT ON COLUMN object_state.state_id is 'id of status';
COMMENT ON COLUMN object_state.valid_from is 'date and time when object entered state';
COMMENT ON COLUMN object_state.valid_to is 'date and time when object leaved state or null if still has this status';
COMMENT ON COLUMN object_state.ohid_from is 'history id of object in the moment of entering state (may be null)';
COMMENT ON COLUMN object_state.ohid_to is 'history id of object in the moment of leaving state or null';
COMMENT ON TABLE object_state_request is 'request for setting manual state';
COMMENT ON COLUMN object_state_request.object_id is 'id of object gaining request state';
COMMENT ON COLUMN object_state_request.state_id is 'id of requested state';
COMMENT ON COLUMN object_state_request.valid_from is 'when object should enter requested state';
COMMENT ON COLUMN object_state_request.valid_to is 'when object should leave requested state';
COMMENT ON COLUMN object_state_request.crdate is 'could be pointed to some list of administation action';
COMMENT ON COLUMN object_state_request.canceled is 'could be pointed to some list of administation action';

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--   Change of 'dnsdate' parameter to actual date of going outzone 
--   wich is represented by 'statechangedate' 
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

UPDATE mail_templates SET template=
'English version of the e-mail is entered below the Czech version

Oznámení o vyřazení domény <?cs var:domain ?> z DNS

Vážený technický správce,

vzhledem k tomu, že jste vedený jako technický kontakt u sady nameserverů
<?cs var:nsset ?>, která je přiřazena k doménovému jménu <?cs var:domain ?>,
dovolujeme si Vás upozornit, že toto doménové jméno bylo ke dni
<?cs var:statechangedate ?> vyřazeno z DNS.


                                             S pozdravem
                                             podpora <?cs var:defaults.company ?>



Notification about withdrawal of the domain <?cs var:domain ?> from DNS

Dear technical administrator,

With regard to the fact that you are named the technical contact for the set
<?cs var:nsset ?> of nameservers, which is assigned to the <?cs var:domain ?>
domain name, we would like to notify you that the aforementioned domain name
was withdrawn from DNS as of <?cs var:statechangedate ?>.


                                             Yours sincerely
                                             support <?cs var:defaults.company ?>
' WHERE id=6;

UPDATE mail_templates SET template=
'
=====================================================================
Oznámení o zrušení / Delete notification 
=====================================================================
Vzhledem ke skutečnosti, že <?cs if:type == #1 ?>kontaktní osoba<?cs elif:type == #2 ?>sada nameserverů<?cs /if ?> <?cs var:handle ?>
<?cs var:name ?> nebyla po stanovenou dobu aktivní, <?cs var:defaults.company ?>
na základě Pravidel registrace ruší ke dni <?cs var:deldate ?> uvedenou
<?cs if:type == #1 ?>kontaktní osobu<?cs elif:type == #2 ?>sadu nameserverů<?cs /if ?>.

With regard to the fact that the <?cs if:type == #1 ?>contact<?cs elif:type == #2 ?>NS set<?cs /if ?> <?cs var:handle ?>
<?cs var:name ?> was not active during the fixed period, <?cs var:defaults.company ?>
is cancelling the aforementioned <?cs if:type == #1 ?>contact<?cs elif:type == #2 ?>set of nameservers<?cs /if ?> as of <?cs var:deldate ?>.
=====================================================================


                                             S pozdravem
                                             podpora <?cs var:defaults.company ?>
' WHERE id=14;

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--    contact/nsset delete
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

INSERT INTO enum_parameters (id, name, val) 
VALUES (11, 'object_registration_protection_period', '6');

CREATE OR REPLACE FUNCTION date_month_test(date, varchar, varchar, varchar)
RETURNS boolean
AS $$
SELECT $1 + ($2||' month')::interval + ($3||' hours')::interval 
       <= CURRENT_TIMESTAMP AT TIME ZONE $4;
$$ IMMUTABLE LANGUAGE SQL;

-- view for actual nsset states
-- for NOW they are not deleted
-- ================= NSSET ========================
DROP VIEW nsset_states;
CREATE VIEW nsset_states AS
SELECT
  o.id AS object_id,
  o.historyid AS object_hid,
  COALESCE(osr.states,'{}') ||
  CASE WHEN NOT(d.nsset ISNULL) THEN ARRAY[16] ELSE '{}' END ||
  CASE WHEN d.nsset ISNULL 
            AND date_month_test(
              GREATEST(
                COALESCE(l.last_linked,o.crdate)::date,
                COALESCE(ob.update,o.crdate)::date
              ),
              ep_mn.val,ep_tm.val,ep_tz.val
            )
            AND NOT (1 = ANY(COALESCE(osr.states,'{}')))
       THEN ARRAY[17] ELSE '{}' END 
  AS states
FROM
  object ob
  JOIN object_registry o ON (ob.id=o.id AND o.type=2)
  JOIN enum_parameters ep_tm ON (ep_tm.id=9)
  JOIN enum_parameters ep_tz ON (ep_tz.id=10)
  JOIN enum_parameters ep_mn ON (ep_mn.id=11)
  LEFT JOIN (
    SELECT DISTINCT nsset FROM domain
  ) AS d ON (d.nsset=o.id)
  LEFT JOIN (
    SELECT object_id, MAX(valid_to) AS last_linked
    FROM object_state
    WHERE state_id=16 GROUP BY object_id
  ) AS l ON (o.id=l.object_id)
  LEFT JOIN object_state_request_now osr ON (o.id=osr.object_id);

-- view for actual contact states
-- ================= CONTACT ========================
DROP VIEW contact_states;
CREATE VIEW contact_states AS
SELECT
  o.id AS object_id,
  o.historyid AS object_hid,
  COALESCE(osr.states,'{}') ||
  CASE WHEN NOT(cl.cid ISNULL) THEN ARRAY[16] ELSE '{}' END ||
  CASE WHEN cl.cid ISNULL 
            AND date_month_test(
              GREATEST(
                COALESCE(l.last_linked,o.crdate)::date,
                COALESCE(ob.update,o.crdate)::date
              ),
              ep_mn.val,ep_tm.val,ep_tz.val
            )
            AND NOT (1 = ANY(COALESCE(osr.states,'{}')))
       THEN ARRAY[17] ELSE '{}' END 
  AS states
FROM
  object ob
  JOIN object_registry o ON (ob.id=o.id AND o.type=1)
  JOIN enum_parameters ep_tm ON (ep_tm.id=9)
  JOIN enum_parameters ep_tz ON (ep_tz.id=10)
  JOIN enum_parameters ep_mn ON (ep_mn.id=11)
  LEFT JOIN (
    SELECT registrant AS cid FROM domain
    UNION
    SELECT contactid AS cid FROM domain_contact_map
    UNION
    SELECT contactid AS cid FROM nsset_contact_map
  ) AS cl ON (o.id=cl.cid)
  LEFT JOIN (
    SELECT object_id, MAX(valid_to) AS last_linked
    FROM object_state
    WHERE state_id=16 GROUP BY object_id
  ) AS l ON (o.id=l.object_id)
  LEFT JOIN object_state_request_now osr ON (o.id=osr.object_id);

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

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--    new indexes into history tables
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

CREATE INDEX domain_history_id_idx ON domain_history (id);
CREATE INDEX domain_history_zone_idx ON domain_history (zone);
CREATE INDEX domain_history_exdate_idx ON domain_history (exdate);
CREATE INDEX domain_history_registrant_idx ON domain_history (registrant);
CREATE INDEX domain_history_nsset_idx ON domain_history (nsset);
CREATE INDEX domain_contact_map_history_contactid_idx ON domain_contact_map_history (contactid);
CREATE INDEX domain_contact_map_history_domainid_idx ON domain_contact_map_history (domainid);
CREATE INDEX nsset_history_id_idx ON nsset_history (id);
CREATE INDEX host_history_nssetid_idx ON host_history (nssetid);
CREATE INDEX host_history_id_idx ON host_history (id);
CREATE INDEX host_ipaddr_map_history_id_idx ON host_ipaddr_map_history (id);
CREATE INDEX host_ipaddr_map_history_hostid_idx ON host_ipaddr_map_history (hostid);
CREATE INDEX host_ipaddr_map_history_nssetid_idx ON host_ipaddr_map_history (nssetid);
CREATE INDEX nsset_contact_map_history_nssetid_idx ON nsset_contact_map_history (nssetid);
CREATE INDEX nsset_contact_map_history_contactid_idx ON nsset_contact_map_history (contactid);
CREATE INDEX contact_history_id_idx ON contact_history (id);
CREATE INDEX enumval_history_domainid_idx ON enumval_history (domainid);
CREATE INDEX object_history_id_idx ON object_history (id);
CREATE INDEX object_history_clid_idx ON object_history (clid);
CREATE INDEX object_history_upid_idx ON object_history (upid);

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--    new indexes into history tables
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

CREATE INDEX domain_history_id_idx ON domain_history (id);
CREATE INDEX domain_history_zone_idx ON domain_history (zone);
CREATE INDEX domain_history_exdate_idx ON domain_history (exdate);
CREATE INDEX domain_history_registrant_idx ON domain_history (registrant);
CREATE INDEX domain_history_nsset_idx ON domain_history (nsset);
CREATE INDEX domain_contact_map_history_contactid_idx ON domain_contact_map_history (contactid);
CREATE INDEX domain_contact_map_history_domainid_idx ON domain_contact_map_history (domainid);
CREATE INDEX nsset_history_id_idx ON nsset_history (id);
CREATE INDEX host_history_nssetid_idx ON host_history (nssetid);
CREATE INDEX host_history_id_idx ON host_history (id);
CREATE INDEX host_ipaddr_map_history_id_idx ON host_ipaddr_map_history (id);
CREATE INDEX host_ipaddr_map_history_hostid_idx ON host_ipaddr_map_history (hostid);
CREATE INDEX host_ipaddr_map_history_nssetid_idx ON host_ipaddr_map_history (nssetid);
CREATE INDEX nsset_contact_map_history_nssetid_idx ON nsset_contact_map_history (nssetid);
CREATE INDEX nsset_contact_map_history_contactid_idx ON nsset_contact_map_history (contactid);
CREATE INDEX contact_history_id_idx ON contact_history (id);
CREATE INDEX enumval_history_domainid_idx ON enumval_history (domainid);
CREATE INDEX object_history_id_idx ON object_history (id);
CREATE INDEX object_history_clid_idx ON object_history (clid);
CREATE INDEX object_history_upid_idx ON object_history (upid);

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--  new table Filters
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

CREATE TABLE Filters (
	ID SERIAL PRIMARY KEY, 
	Type SMALLINT NOT NULL, 
	Name VARCHAR(255) NOT NULL, 
	UserID INTEGER NOT NULL, 
	GroupID INTEGER,
	Data TEXT NOT NULL
	);

COMMENT ON TABLE Filters is
'Table for saved object filters';

COMMENT ON COLUMN Filters.ID is 'unique automatically generated identifier';
COMMENT ON COLUMN Filters.Type is 'filter object type -- 0 = filter on filter, 1 = filter on registrar, 2 = filter on object, 3 = filter on contact, 4 = filter on nsset, 5 = filter on domain, 6 = filter on action, 7 = filter on invoice, 8 = filter on authinfo, 9 = filter on mail';
COMMENT ON COLUMN Filters.Name is 'human readable filter name';
COMMENT ON COLUMN Filters.UserID is 'filter creator';
COMMENT ON COLUMN Filters.GroupID is 'filter accessibility for group';
COMMENT ON COLUMN Filters.Data is 'filter definition';
