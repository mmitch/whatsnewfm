%define	name	whatsnewfm
%define version 0.5.1
%define release 1

Summary:	A utility to filter the daily newsletter from freshmeat.net
Name:		%{name}
Version:	%{version}
Release:	%{release}
Copyright:	GPL
Group:		Applications/Databases
Source:		%{name}-%{version}.tar.gz
BuildRoot:	/var/tmp/%{name}-%{version}
BuildArchitectures:	noarch
%description
whatsnewfm is a utility to filter the daily newsletter from freshmeat.net

The main purpose is to cut the huge newsletter to a smaller size by
only showing items that you didn't see before.

The items already seen will be stored in a database.  After some time,
the items expire and will be shown again the next time they are
included in a newsletter.

If you find an item that you consider particularly useful, you can add
it to a "hot" list.  Items in the hot list are checked for updates so
that you don't miss anything about your favourite programs.

%prep
%setup
%build

%install
mkdir -p $RPM_BUILD_ROOT/usr/bin/
cp whatsnewfm.pl $RPM_BUILD_ROOT/usr/bin/
mkdir -p $RPM_BUILD_ROOT/usr/man/man1/
pod2man whatsnewfm.pl | gzip -9 > $RPM_BUILD_ROOT/usr/man/man1/whatsnewfm.pl.1.gz

%files
%doc README COPYING HISTORY whatsnewfmrc.sample welcome
/usr/bin/whatsnewfm.pl
/usr/man/man1/whatsnewfm.pl.1.gz

%clean
rm -rf $RPM_BUILD_ROOT
