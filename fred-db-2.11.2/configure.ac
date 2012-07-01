AC_INIT([fred-db], 2.11.2)
AC_CONFIG_FILES([Makefile
		 fred-db.spec fred-dbmanager])
AM_INIT_AUTOMAKE([-Wall -Werror])

#test if sed is present
AC_PROG_SED

#function to check if directory exists (arguments same as AC_CHECK_FILE)
#with disable/enable checking option
AC_DEFUN([AC_CHECK_DIR],
[
if test $CHECK = yes; then
    AC_MSG_CHECKING(for $1)
    if test -d $1; then
        AC_MSG_RESULT(yes)
        $2
    else
        AC_MSG_RESULT(no)
        $3
    fi
else
    AC_MSG_WARN([Checking for $1 is overriden])
fi
])

#function to check if file exists (arguments same as AC_CHECK_FILE)
#with disable/enable checking option
AC_DEFUN([AC_CHECK_FIL],
[
if test $CHECK = yes; then
    AC_MSG_CHECKING(for $1)
    if test -f $1; then
        AC_MSG_RESULT(yes)
        $2
    else
        AC_MSG_RESULT(no)
        $3
    fi
else
    AC_MSG_WARN([Checking for $1 is overriden])
fi
])


### debian, ubuntu
AC_DEFUN([AC_DEBIAN_DIRS],
[
if test $1 = yes; then
    if test "$PGVERSION" = ""; then
        ### get highest version
        for i in `ls /etc/postgresql/`
        do
            ver=$i
        done
    else
        ver=$PGVERSION
    fi
    AC_SUBST([PGDATADIR], [/var/lib/postgresql/$ver/main/])
    AC_SUBST([PGHBADIR], [/etc/postgresql/$ver/main/])
    AC_SUBST([PGBINDIR], [/usr/lib/postgresql/$ver/bin/])
fi
])

### redhat, fedora, suse
AC_DEFUN([AC_REDHAT_DIRS],
[
if test $1 = yes; then
    ### on fedora is pointless to test directories
    ### because of access rights
    AC_SUBST([CHECK], [no])
    AC_SUBST([PGDATADIR], [/var/lib/pgsql/data])
    AC_SUBST([PGHBADIR], [/var/lib/pgsql/data])
    AC_SUBST([PGBINDIR], [/usr/bin/])
fi
])

### arch, gentoo
AC_DEFUN([AC_DEFAULT_DIRS],
[
if test $1 = yes; then
    AC_SUBST([PGDATADIR], [/var/lib/postgres/data])
    AC_SUBST([PGHBADIR], [/var/lib/postgres/data])
    AC_SUBST([PGBINDIR], [/usr/bin/])
fi
])

#this function decide on what system
#is configure script executed
AC_DEFUN([AC_AUTO_LOAD_PATHS],
[
if test $1 = yes; then
    if test -f /etc/redhat-release; then
        AC_REDHAT_DIRS(yes)
    elif test -f /etc/SuSE-release; then
        AC_REDHAT_DIRS(yes)
    elif test -f /etc/debian_version; then
        AC_DEBIAN_DIRS(yes)
    else
        AC_DEFAULT_DIRS(yes)
    fi
fi
])

#function to determine on which port database listening
#by default it is port from postgresql.conf file,
#when this file cannot be found, configure use port 5432
AC_DEFUN([AC_AUTO_PORT],
[
  if test "$1" = ""; then
    if test -f $PGHBADIR/postgresql.conf; then
      port=`grep -E '^port' $PGHBADIR/postgresql.conf | tr -d " \t" | cut -d'#' -f1 | cut -c6-`
      if test "$port" = ""; then
        port="5432"
      fi
    else
      port="5432"
    fi
  else
    port="$1"
  fi
  AC_SUBST([DBPORT], [$port])
])

#function to check if method value is valid
AC_DEFUN([AC_TEST_METHOD],
[
AC_MSG_CHECKING(whether method $1 is valid)
case "$1" in
    "trust")a=1;;
    "reject")a=1;;
    "md5")a=1;;
    "crypt")a=1;;
    "password")a=1;;
    "krb5")a=1;;
    "ident")a=1;;
    "pam")a=1;;
    "ldap")a=1;;
    *)a=0;;
esac
if test $a -eq 1 
then
    AC_MSG_RESULT(yes)
    $2
else
    AC_MSG_RESULT(no)
    $3
fi])

#if check postgresql directories and files
AC_ARG_WITH([check], [AS_HELP_STRING([--with-check],
            [Whether check directories and files existence [yes]])],
            [AC_SUBST([CHECK], [$withval])],
            [AC_SUBST([CHECK], [yes])])

#postgresql version, meaningfull mainly on debian
AC_ARG_WITH([pgversion], [AS_HELP_STRING([--with-pgversion],
	    [Which version of PostgreSQL use (only for Debian/Ubuntu) (by default is used latest found)])],
	    [AC_SUBST([PGVERSION], [$withval])],
	    [AC_SUBST([PGVERSION], [""])])

AC_ARG_WITH([autodetect], [AS_HELP_STRING([--with-autodetect],
            [Whether automatically detect proper postgres direstories and files [yes]])],
            [AC_AUTO_LOAD_PATHS($withval)], [AC_AUTO_LOAD_PATHS(yes)])


AC_ARG_WITH([redhat], [AS_HELP_STRING([--with-redhat],
            [Use redhat directories paths (also valid for Fedora, SuSE)])],
            [AC_REDHAT_DIRS($withval)], [])

AC_ARG_WITH([debian], [AS_HELP_STRING([--with-debian],
            [Use Debian directories paths (also valid for Ubuntu)])],
            [AC_DEBIAN_DIRS($withval)], [])

#check for directory containing postmaster.pid file
#on fedora it is /var/lib/pgsql/data, on gentoo and arch /var/lib/postgres/data
#and on debian and ubuntu /var/lib/postgresql/<version>/main/
#this directory is sometimes and somewhere mentioned as $PGDATA
AC_ARG_WITH([pgdatadir], [AS_HELP_STRING([--with-pgdatadir],
            [Directory containing postmaster.pid  file [/var/lib/postgres/data]])],
            [AC_SUBST([PGDATADIR], [$withval])],
            [])

#check for directory containing pg_hba.conf file
#on fedora it is /var/lib/pgsql/data, on gentoo and arch /var/lib/postgres/data
#and on debian and ubuntu /etc/postgres/<version>/main
AC_ARG_WITH([pghbadir], [AS_HELP_STRING([--with-pghbadir],
            [Directory containing pg_hba.conf  file [$PGDATADIR]])],
            [AC_SUBST([PGHBADIR], [$withval])],
            [])

#bin directory for postgres, must contain pg_ctl, createuser, createdb, createlang, psql
AC_ARG_WITH([pgbindir], [AS_HELP_STRING([--with-pgbindir],
            [Directory containing postgresql binary files (pg_ctl, createuser, ...) [/usr/bin]])],
            [AC_SUBST([PGBINDIR], [$withval])],
            [])

AC_CHECK_DIR([$PGHBADIR], [], [AC_MSG_ERROR(
              [Directory "$PGHBADIR" does not exists (use --with-pghbadir)])])
AC_CHECK_DIR([$PGDATADIR], [], [AC_MSG_ERROR(
              [Directory "$PGDATADIR" does not exists (use --with-pgdatadir)])])
AC_CHECK_FIL([$PGBINDIR/pg_ctl], [], [AC_MSG_ERROR(
               [File "$PGBINDIR/pg_ctl" does not exists (use --with-pgbindir)])])
AC_CHECK_FIL([$PGBINDIR/createuser], [], [AC_MSG_ERROR(
               [File "$PGBINDIR/createuser" does not exists (use --with-pgbindir)])])
AC_CHECK_FIL([$PGBINDIR/createdb], [], [AC_MSG_ERROR(
               [File "$PGBINDIR/createdb" does not exists (use --with-pgbindir)])])
AC_CHECK_FIL([$PGBINDIR/createlang], [], [AC_MSG_ERROR(
               [File "$PGBINDIR/createlang" does not exists (use --with-pgbindir)])])
AC_CHECK_FIL([$PGBINDIR/psql], [], [AC_MSG_ERROR(
               [File "$PGBINDIR/psql" does not exists (use --with-pgbindir)])])

#sql script with database structure

#database name
AC_ARG_WITH([dbname], [AS_HELP_STRING([--with-dbname],
            [Name of database [fred]])],
            [AC_SUBST([DBNAME], [$withval])],
            [AC_SUBST([DBNAME], [fred])])

#database user (owner)
AC_ARG_WITH([dbuser], [AS_HELP_STRING([--with-dbuser],
            [Database user (owner) [fred]])],
            [AC_SUBST([DBUSER], [$withval])],
            [AC_SUBST([DBUSER], [fred])])

#database port (host is always localhost)
AC_ARG_WITH([dbport], [AS_HELP_STRING([--with-dbport],
            [TCP port to database [5432]])],
	    [AC_AUTO_PORT($withval)],
	    [AC_AUTO_PORT()])

#password cannot be enteren in non-interactive mode,
#createuser command with -P argument promt for password
### #database password
### AC_ARG_WITH([dbpass], [AS_HELP_STRING([--with-dbpass],
            ### [Database user password []])],
            ### [AC_SUBST([DBPASS], [$withval])],
            ### [AC_SUBST([DBPASS], [""])])

### #database host
### AC_ARG_WITH([hostname], [AS_HELP_STRING([--with-hostname],
            ### [Database host address [localhost]])],
            ### [AC_SUBST([HOSTNAME], [$withval])],
            ### [AC_SUBST([HOSTNAME], [localhost])])

#database cidr-address for IPv4(in file pg_hba.conf)
AC_ARG_WITH([cidripv4], [AS_HELP_STRING([--with-cidripv4],
            [Specified the set of allowed hosts for IPv4 [127.0.0.1/32]])],
            [AC_SUBST([CIDRIPV4], [$withval])],
            [AC_SUBST([CIDRIPV4], [127.0.0.1/32])])

#cidrv6 address specifies the set of hosts to mathch record for ipv6
AC_ARG_WITH([cidripv6], [AS_HELP_STRING([--with-cidripv6],
            [Specified the set of allowed hosts for IPv6 [::1/128]])],
            [AC_SUBST([CIDRIPV6], [$withval])],
            [AC_SUBST([CIDRIPV6], [::1/128])])

#method
AC_ARG_WITH([method], [AS_HELP_STRING([--with-method],
           [Method of control when accessing database [trust]])],
           [AC_SUBST([METHOD], [$withval])],
           [AC_SUBST([METHOD], [trust])])
AC_TEST_METHOD([$METHOD], [], [AC_MSG_ERROR(
                [Method "$METHOD" is not valid. See comments in your pg_hba.conf file])])

### #option
### AC_ARG_WITH([option], [AS_HELP_STRING([--with-option],
            ### [Ident is ident map or name of the PAM service []])],
            ### [AC_SUBST([OPTION], [$withval])],
            ### [AC_SUBST([OPTION], [""])])

AC_OUTPUT
