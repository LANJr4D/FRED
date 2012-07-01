---
--- UPGRADE SCRIPT 2.2.0 -> 2.3.0 (data definition part)
---

---
--- Ticket #2099 Registrar refactoring
---

ALTER TABLE registrarinvoice ADD COLUMN toDate date;

---
--- Ticket #1670 Banking refactoring
---

CREATE TABLE bank_statement 
(
    id serial NOT NULL PRIMARY KEY, -- unique primary key
    account_id int  REFERENCES bank_account, -- processing for given account link to account tabel
    num int, -- serial number statement
    create_date date , --  create date of a statement
    balance_old_date date , -- date of a last balance
    balance_old numeric(10,2) , -- old balance
    balance_new numeric(10,2) ,  -- new balance
    balance_credit  numeric(10,2) , -- income during statement ( credit balance )
    balance_debet numeric(10,2), -- expenses during statement ( debet balance )
    file_id INTEGER REFERENCES Files default NULL
);

comment on column bank_statement.id is 'unique automatically generated identifier';
comment on column bank_statement.account_id is 'link to used bank account';
comment on column bank_statement.num is 'statements number';
comment on column bank_statement.create_date is 'statement creation date';
comment on column bank_statement.balance_old is 'old balance state';
comment on column bank_statement.balance_credit is 'income during statement';
comment on column bank_statement.balance_debet is 'expenses during statement';
comment on column bank_statement.file_id is 'xml file identifier number';


CREATE TABLE bank_payment
(
    id serial NOT NULL PRIMARY KEY, -- unique primary key
    statement_id int  REFERENCES bank_statement default null, -- link into table heads of bank statements
    account_id int  REFERENCES bank_account default null, -- link into table of accounts
    account_number varchar(17)  NOT NULL , -- contra-account number from which came or was sent a payment
    bank_code varchar(4) NOT NULL,   -- bank code
    code int, -- account code 1 debet item 2 credit item 4  cancel debet 5 cancel credit 
    type int NOT NULL default 1, -- transfer type
    status int, -- payment status
    KonstSym varchar(10), -- constant symbol ( it contains bank code too )
    VarSymb varchar(10), -- variable symbol
    SpecSymb varchar(10), -- constant symbol
    price numeric(10,2) NOT NULL,  -- applied amount if a debet is negative amount 
    account_evid varchar(20), -- account evidence 
    account_date date NOT NULL, --  accounting date of credit or sending 
    account_memo  varchar(64), -- note
    invoice_ID INTEGER REFERENCES Invoice default NULL, -- null if it isn't income payment of process otherwise link to advance invoice
    account_name  varchar(64), -- account name
    crtime timestamp NOT NULL default now(),
    UNIQUE(account_id, account_evid)
);

comment on column bank_payment.id is 'unique automatically generated identifier';
comment on column bank_payment.statement_id is 'link to statement head';
comment on column bank_payment.account_id is 'link to account table';
comment on column bank_payment.account_number is 'contra-account number from which came or was sent a payment';
comment on column bank_payment.bank_code is 'contra-account bank code';
comment on column bank_payment.code is 'operation code (1-debet item, 2-credit item, 4-cancel debet, 5-cancel credit)';
comment on column bank_payment.type is 'transfer type (1-not decided (not processed), 2-from/to registrar, 3-from/to bank, 4-between our own accounts, 5-related to academia, 6-other transfers';
comment on column bank_payment.status is 'payment status (1-Realized (only this should be further processed), 2-Partially realized, 3-Not realized, 4-Suspended, 5-Ended, 6-Waiting for clearing )';
comment on column bank_payment.KonstSym is 'constant symbol (contains bank code too)';
comment on column bank_payment.VarSymb is 'variable symbol';
comment on column bank_payment.SpecSymb is 'spec symbol';
comment on column bank_payment.price is 'applied positive(credit) or negative(debet) amount';
comment on column bank_payment.account_evid is 'account evidence';
comment on column bank_payment.account_date is 'accounting date';
comment on column bank_payment.account_memo is 'note';
comment on column bank_payment.invoice_ID is 'null if it is not income payment of process otherwise link to proper invoice';
comment on column bank_payment.account_name is 'account name';
comment on column bank_payment.crtime is 'create timestamp';


ALTER TABLE registrar ADD regex varchar(30) DEFAULT NULL;
ALTER TABLE invoice ALTER COLUMN zone DROP NOT NULL;
ALTER TABLE bank_account ALTER COLUMN balance SET DEFAULT 0.0;

---
--- Drop references to action table
---
ALTER TABLE history DROP CONSTRAINT history_action_fkey;
ALTER TABLE public_request DROP CONSTRAINT public_request_epp_action_id_fkey;
ALTER TABLE auth_info_requests DROP CONSTRAINT auth_info_requests_epp_action_id_fkey;
