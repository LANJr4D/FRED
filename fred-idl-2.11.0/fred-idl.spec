Name:		fred-idl
Version:	2.11.0
Release:	1
Summary:	FRED - idl interface files

Group:		Applications/Utils
License:	GPL
URL:		http://fred.nic.cz
Source0:	%{name}-%{version}.tar.gz
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:	noarch

%description
FRED (Free Registry for Enum and Domain) is free registry system for 
managing domain registrations. This package contains idl files with definition
of corba interfaces to server

%prep
%setup -q

%build
%configure

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/usr/share/idl/fred/*.idl

%changelog
