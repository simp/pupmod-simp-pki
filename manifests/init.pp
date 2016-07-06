# == Class: pki
#
# This class provides the capability to manage non-Puppet PKI keys that are
# hosted on the Puppet server. It requires keys to be managed under the PKI
# module at ${environment}/modules/pki/files/keydist.
#
# The keydist directory must have the following structure:
#
# ${environment}/modules/pki/files/keydist/
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
  $enable_audit = defined('$::enable_auditing') ? { true => $::enable_auditing, default => hiera('enable_auditing', true) },
  $sync_purge = true,
  $private_key_source = "puppet:///modules/pki/keydist/${::fqdn}/${::fqdn}.pem",
  $public_key_source  = "puppet:///modules/pki/keydist/${::fqdn}/${::fqdn}.pub",
  $cacerts_sources     = [
      'puppet:///modules/pki/keydist/cacerts',
      "puppet:///modules/pki/keydist/cacerts/${::fqdn}/cacerts"
  ]
) {
  validate_bool($enable_audit)
  validate_bool($sync_purge)
  validate_array($cacerts_sources)

  compliance_map()

  # These are for reference by other modules and provide a consistent interface
  # for future updates.
  $pki_dir         = '/etc/pki'
  $private_key_dir = "${pki_dir}/private"
  $public_key_dir  = "${pki_dir}/public"
  $private_key     = "${private_key_dir}/${::fqdn}.pem"
  $public_key      = "${public_key_dir}/${::fqdn}.pub"
  $cacerts         = "${pki_dir}/cacerts"
  $cacertfile      = "${pki_dir}/cacerts/cacerts.pem"

  # For those that are pedantically aware...
  $public_cert_dir = $public_key_dir
  $public_cert     = $public_key

  if $enable_audit {
    include '::auditd'

    # Add audit rules for PKI key material

    auditd::add_rules { 'pki':
      content => "-w ${private_key_dir} -p wa -k PKI
-w ${public_key_dir} -p wa -k PKI
-w ${cacerts} -p wa -k PKI
-w ${private_key} -p wa -k PKI
-w ${public_key} -p wa -k PKI"
    }
  }

  file { $pki_dir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0655',
    tag    => 'firstrun'
  }

  file { $private_key_dir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0550',
    purge  => true,
    tag    => 'firstrun'
  }

  file { $public_key_dir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    purge  => true,
    tag    => 'firstrun'
  }

  file { $private_key:
    owner  => 'root',
    group  => 'root',
    mode   => '0440',
    source => $private_key_source,
    tag    => 'firstrun'
  }

  file { $public_key:
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    source => $public_key_source,
    tag    => 'firstrun'
  }

  # This is a temporary holding space for certs coming from the Puppet server.
  # The pki_cert_sync type will take care of placing them appropriately.
  $ingress = "${pki_dir}/.cacerts_ingress"

  file { $ingress:
    ensure       => 'directory',
    owner        => 'root',
    group        => 'root',
    recurse      => true,
    mode         => '0644',
    purge        => true,
    force        => true,
    seltype      => 'cert_t',
    source       => $cacerts_sources,
    sourceselect => 'all',
    tag          => 'firstrun'
  }

  file { $cacerts:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    seltype => 'cert_t',
    recurse => true,
    tag     => 'firstrun'
  }

  pki_cert_sync { $cacerts:
    source => $ingress,
    tag    => 'firstrun',
    purge  => $sync_purge
  }
}
