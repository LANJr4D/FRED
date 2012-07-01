pkgdata_DATA = structure.sql
sbin_SCRIPTS = fred-dbmanager
upgradesdir = $(pkgdatadir)/upgrades
upgrades_DATA = $(srcdir)/upgrades/*.sql

CLEANFILES = structure.sql fred-dbmanager
EXTRA_DIST = $(srcdir)/sql/*.sql $(srcdir)/orderedsql.sh \
             fred-db.spec $(srcdir)/upgrades/*.sql

structure.sql: $(srcdir)/sql/*.sql $(srcdir)/orderedsql.sh
	$(srcdir)/orderedsql.sh > structure.sql

