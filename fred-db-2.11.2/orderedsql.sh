#!/bin/bash
# printing-out sql command in right order to create of new database
#base system

set -e

DIR=$(dirname $0)/sql

write_script() 
{
    cat $DIR/array_util_func.sql
	cat $DIR/error.sql
	cat $DIR/enum_reason.sql
	cat $DIR/enum_ssntype.sql
	cat $DIR/enum_country.sql
	cat $DIR/enum_cs_country.sql
	cat $DIR/zone.sql
	#registar and registraracl  tables
	cat $DIR/registrar.sql
	# object table
	cat $DIR/history_base.sql
	cat $DIR/ccreg.sql
	cat $DIR/history.sql
	#zone generator
	cat $DIR/genzone.sql
	#adif
	cat $DIR/admin.sql  
	#filemanager
	cat $DIR/filemanager.sql
	#filemanager's file for certification evaluation pdf
	cat $DIR/certification_file_dml.sql
	#mailer
	cat $DIR/mail_notify.sql
	cat $DIR/mail_templates.sql
	# banking
	cat $DIR/enum_bank_code.sql
	cat $DIR/credit_ddl.sql
	cat $DIR/invoice.sql
	cat $DIR/bank.sql
	cat $DIR/bank_ddl_new.sql
	#tech-check
	cat $DIR/techcheck.sql
	cat $DIR/info_buffer.sql
	# common functions
	cat $DIR/func.sql
	# table with parameters
	cat $DIR/enum_params.sql
	# keyset
	cat $DIR/keyset.sql
	# state and poll
	cat $DIR/state.sql
	cat $DIR/poll.sql
    cat $DIR/request_fee_ddl.sql
    cat $DIR/request_fee_dml.sql
	# notify mailer
	cat $DIR/notify_new.sql
	# list of tld domains
	cat $DIR/enum_tlds.sql
	# new table with filters
	cat $DIR/filters.sql
	# new indexes for history tables
	cat $DIR/index.sql
	# new table for requests from public
	cat $DIR/public_request.sql
	# registrar's certifications and groups
	cat $DIR/registrar_certification_ddl.sql
    cat $DIR/registrar_disconnect.sql
    # mojeid
    cat $DIR/registry_dml_mojeid.sql
    # contact reminder
    cat $DIR/reminder_ddl.sql
    cat $DIR/reminder_dml.sql
    # monitoring
    cat $DIR/monitoring_dml.sql
    # epp login IDs
    cat $DIR/epp_login.sql
}

usage()
{
	echo "$0 : Create database installation .sql script. It accepts one of these options: "
	echo "		--without-log exclude logging tables (used by fred-logd daemon) "
	echo "		--help 	   display this message "
}

case "$1" in
	--without-log)
		write_script
		;;
	--help) 
		usage
		;;
	*)
		write_script
        cat $DIR/logger_ddl.sql		
        cat $DIR/logger_dml_whois.sql
        cat $DIR/logger_dml_webwhois.sql
        cat $DIR/logger_dml_pubrequest.sql
        cat $DIR/logger_dml_epp.sql
        cat $DIR/logger_dml_webadmin.sql
        cat $DIR/logger_dml_intranet.sql
        cat $DIR/logger_dml_mojeid.sql
        cat $DIR/logger_dml_domainbrowser.sql
        cat $DIR/logger_dml.sql
        cat $DIR/logger_dml_pubrequest_result.sql
        cat $DIR/logger_partitioning.sql
		;;
esac
