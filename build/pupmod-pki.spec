Summary: PKI Puppet Module
Name: pupmod-pki
Version: 4.1.0
Release: 7
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: pupmod-auditd >= 2.0.0-0
Requires: puppet >= 3.7.4
Requires: simp-bootstrap >= 4.2.0
Buildarch: noarch
Obsoletes: pupmod-pki-test >= 0.0.1

Prefix: %{_sysconfdir}/puppet/environments/simp/modules

%description
This Puppet module provides the ability to distribute and manage PKI keys for
all of your managed systems.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/pki
mkdir -p %{buildroot}/%{prefix}/pki/files/keydist
mkdir -p %{buildroot}/%{prefix}/pki/files/keydist/mcollective

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/pki
done

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/pki

%files
%defattr(0640,root,puppet,0750)
%{prefix}/pki

%post
#!/bin/sh

if [ -d %{prefix}/pki/plugins ]; then
  /bin/mv %{prefix}/pki/plugins %{prefix}/pki/plugins.bak
fi

%postun
# Post uninstall stuff

%changelog
* Mon Dec 14 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-7
- Remove erroneous test5.simp.vm key from the keydist directory

* Mon Nov 09 2015 Chris Tessmer <chris.tessmer@onyxpoint.com> - 4.1.0-6
- Migration to simplib and simpcat (lib/ only)

* Tue Oct 13 2015 Nick Markowski <nmarkowski@keywcorp.com> - 4.1.0-5
- If a directory is placed in keydist/cacerts, the directory structure is copied
  to pki/cacerts, and all certs in subdirectories are appended to cacerts.pem.
- If a directory is removed from keydist/cacerts, it is now forcibly removed
  from .cacerts_ingress.

* Thu Feb 12 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-4
- Moved things to the new 'simp' environment
- Ensure the requirements on packages are appropriately defined

* Mon Feb 09 2015 Nick Markowski <nmarkowski@keywcorp.com> - 4.1.0-3
- A public RSA key is now generated off off the system private key, and
  placed in /etc/pki/public/fqdn_rsa.pem

* Sun Jun 22 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-2
- Removed MD5 file checksums for FIPS compliance.

* Fri Jun 20 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-2
- Modified code in the pki_cert_sync provider for Ruby 2
  compatibility.

* Thu May 15 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-1
- Updated pki_cert_sync to (re)build a concatenated cacerts.pem file which is
  a bundled file of all valid CA certs in /etc/pki/cacerts.

* Tue Apr 08 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-0
- Updated manifests for puppet 3 and hiera compatibility.
- Refactored manifests to pass all lint tests.
- Removed the pki::pre class as all functionality now exists in the pki class.
- Added spec tests.

* Mon Mar 17 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 3.0.0-0
- Added a pki::copy define for properly copying the entire PKI set to an
  alternate location on the system with proper ordering.
- Rolled the pki::pre class into the main pki class.

* Mon Feb 17 2014 Kendall Moore <kmoore@keywcorp.com> - 2.0.0-6
- Added autorequire to pki_cert_sync for file destination.

* Fri May 31 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.0-5
- Created a native type to replace the hack set of execs for CA certificate
  synchronization. This is not perfect but it is far faster and better.
  Ideally, the type would be able to pull the files from the Puppet server
  itself. Also, the file resource for '/etc/pki/cacerts' was preserved for
  legacy code notification compatibility.

* Wed Apr 11 2012 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.0-4
- Moved mit-tests to /usr/share/simp...
- Updated pp files to better meet Puppet's recommended style guide.

* Fri Mar 02 2012 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.0-3
- Improved test stubs.

* Wed Dec 14 2011 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.0-2
- Added an initial suite of tests
- Fixed the creation of certificate hashes and now hash on 'subject' not 'issuer'.
- Updated the spec file to not require a separate file list.
- The certificate hash script had errors with cert hashes beginning with a '0'
  as well as hashing on the issuer not the subject. Also, cleaned up the way
  the intermediate directory cleanup is handled.

* Thu Oct 27 2011 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.0-1
- Updated the PKI module to create a two-step certificate placement so that the
  certificate hashes can be generated on the client. This is done due to RHEL6
  using a different hashing algorithm than RHEL5

* Tue Jan 11 2011 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.0-0
- Refactored for SIMP-2.0.0-alpha release

* Tue Oct 26 2010 Trevor Vaughan <tvaughan@onyxpoint.com> - 1-2
- Converting all spec files to check for directories prior to copy.

* Thu Jun 10 2010 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0-1
- No templates to copy in caused an RPM build failure.

* Mon May 24 2010 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0-0
- Code refactor and doc updates.
