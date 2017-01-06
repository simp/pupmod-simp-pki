# This class provides the capability to manage non-Puppet PKI keys that are
# hosted on the Puppet server. It requires keys to be managed under the PKI
# module at ``${environment}/modules/pki/files/keydist``.
#
# The keydist directory must have the following structure:
#
# * ``${environment}/modules/pki/files/keydist/``
#     * cacerts
#         * Any X.509 PEM formatted CA certificates that you want to serve to
#           your clients.
#     * <fqdn>
#         * cacerts
#             * Any X.509 PEM formatted CA certificates that you want to serve
#               to this particular client.
#         * <fqdn>.pem -> Host Private Key
#         * <fqdn>.pub -> Host Public Key
#
# @param auditd
#   Whether or not to enable auditing of the system keys
#
# @param sync_purge
#   Whether or not the PKI sync type should purge the destination directory
#
#   * If set to ``true`` (the default), the ``/etc/pki/cacerts`` directory
#     will have any non-recognized certificates removed.
#
# @param private_key_source
#   The source of the private key content
#
#   * This parameter accepts the same values as the ``file`` type's ``source``
#     parameter
#
# @param public_key_source
#   The source of the private key content
#
#   * This parameter accepts the same values as the ``file`` type's ``source``
#     parameter
#
# @author Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class pki (
  Stdlib::Absolutepath $base               = simplib::lookup('simp_options::pki::source', { 'default_value' => '/etc/pki/simp' }),
  String               $private_key_source = "puppet:///modules/${module_name}/keydist/${facts['fqdn']}/${facts['fqdn']}.pem",
  String               $public_key_source  = "puppet:///modules/${module_name}/keydist/${facts['fqdn']}/${facts['fqdn']}.pub",
  Boolean              $auditd             = simplib::lookup('simp_options::auditd', { 'default_value' => false}),
  Boolean              $sync_purge         = true,
  Array[String]        $cacerts_sources    = [
    "puppet:///modules/${module_name}/keydist/cacerts",
    "puppet:///modules/${module_name}/keydist/cacerts/${facts['fqdn']}/cacerts"
  ]
) {

  # These are for reference by other modules and provide a consistent interface
  # for future updates.
  $private_key_dir = "${base}/private"
  $public_key_dir  = "${base}/public"
  $private_key     = "${private_key_dir}/${facts['fqdn']}.pem"
  $public_key      = "${public_key_dir}/${facts['fqdn']}.pub"
  $cacerts         = "${base}/cacerts"
  $cacertfile      = "${base}/cacerts/cacerts.pem"

  if $auditd {
    include '::auditd'

    # Add audit rules for PKI key material

    auditd::add_rules { 'pki':
      content => "-w ${base} -p wa -k PKI"
    }
  }

  file { $base:
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
    owner     => 'root',
    group     => 'root',
    mode      => '0440',
    source    => $private_key_source,
    tag       => 'firstrun',
    seltype   => 'cert_t',
    show_diff => false
  }

  file { $public_key:
    owner     => 'root',
    group     => 'root',
    mode      => '0444',
    source    => $public_key_source,
    tag       => 'firstrun',
    seltype   => 'cert_t',
    show_diff => false
  }

  # This is a temporary holding space for certs coming from the Puppet server.
  # The pki_cert_sync type will take care of placing them appropriately.
  $ingress = "${base}/.cacerts_ingress"

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
    tag          => 'firstrun',
    show_diff    => false
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
