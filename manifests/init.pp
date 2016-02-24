# == Class: pki
#
# This class provides the capability to manage non-Puppet PKI keys that are
# hosted on the Puppet server. It requires keys to be managed under the PKI
# module at modules/pki/files/keydist.
#
# The keydist directory must have the following structure:
#
# /etc/puppet/keydist
#  - cacerts
#    - Any X.509 PEM formatted CA certificates that you want to serve to your
#      clients.
#  - <fqdn>
#    - cacerts
#      - Any X.509 PEM formatted CA certificates that you want to serve to this
#        particular client.
#    - <fqdn>.pem -> Host Private Key
#    - <fqdn>.pub -> Host Public Key
#
# == Parameters
#
# [*enable_audit*]
#  Type: Boolean
#  Default: true
#    Whether or not to enable auditing of the system keys.
#
# [*sync_purge*]
#  Type: Boolean
#  Default: true
#    Whether or not the PKI sync type should purge the destination directory.
#    If set to 'true' (the default), the /etc/pki/cacerts directory will have
#    any non-recognized certificates removed.
#
# [*private_key_source*]
#  Type: String
#  Default: puppet:///modules/pki/keydist/${::fqdn}/${::fqdn}.pem
#    The source of the private key content. This parameter accepts the same
#    values as the file type's source parameter.
#
# [*public_key_source*]
#  Type: String
#  Default: puppet:///modules/pki/keydist/${::fqdn}/${::fqdn}.pem
#    The source of the private key content. This parameter accepts the same
#    values as the file type's source parameter.
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class pki (
  $enable_audit = true,
  $sync_purge = true,
  $private_key_source = "puppet:///modules/pki/keydist/${::fqdn}/${::fqdn}.pem",
  $public_key_source  = "puppet:///modules/pki/keydist/${::fqdn}/${::fqdn}.pub",
) {
  validate_bool($enable_audit)
  validate_bool($sync_purge)

  compliance_map()

  if $enable_audit {
    include 'auditd'

    # Add audit rules for PKI key material

    auditd::add_rules { 'pki':
      content => "-w /etc/pki/private -p wa -k PKI
-w /etc/pki/public -p wa -k PKI
-w /etc/pki/cacerts -p wa -k PKI
-w /etc/pki/private/${::fqdn}.pem -p wa -k PKI
-w /etc/pki/public/${::fqdn}.pub -p wa -k PKI"
    }
  }

  file { '/etc/pki':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0655',
    tag    => 'firstrun'
  }

  file { '/etc/pki/private':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0550',
    purge  => true,
    tag    => 'firstrun'
  }

  file { '/etc/pki/public':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    purge  => true,
    tag    => 'firstrun'
  }

  file { "/etc/pki/private/${::fqdn}.pem":
    owner  => 'root',
    group  => 'root',
    mode   => '0440',
    source => $private_key_source,
    tag    => 'firstrun'
  }

  file { "/etc/pki/public/${::fqdn}.pub":
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    source => $public_key_source,
    tag    => 'firstrun'
  }

  # This is a temporary holding space for certs coming from the Puppet server.
  # The pki_cert_sync type will take care of placing them appropriately.
  $ingress = '/etc/pki/.cacerts_ingress'

  file { $ingress:
    ensure       => 'directory',
    owner        => 'root',
    group        => 'root',
    recurse      => true,
    mode         => '0644',
    purge        => true,
    force        => true,
    seltype      => 'cert_t',
    source       => [
      'puppet:///modules/pki/keydist/cacerts',
      "puppet:///modules/pki/keydist/cacerts/${::fqdn}/cacerts"
    ],
    sourceselect => 'all',
    tag          => 'firstrun'
  }

  file { '/etc/pki/cacerts':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    seltype => 'cert_t',
    recurse => true,
    tag     => 'firstrun'
  }

  pki_cert_sync { '/etc/pki/cacerts':
    source => $ingress,
    tag    => 'firstrun',
    purge  => $sync_purge
  }
}
