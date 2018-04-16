# This class provides the capability to manage non-Puppet PKI keys that are
# hosted on the Puppet server.
#
# The keydist directory must have the following structure:
#
# * `${codedir}/${environment}/modules/#{module_name}/files/keydist/`
#     * `cacerts`
#         * Any X.509 PEM formatted CA certificates that you want to serve to
#           your clients.
#     * `<fqdn>`
#         * `cacerts`
#             * Any X.509 PEM formatted CA certificates that you want to serve
#               to this particular client.
#         * `<fqdn>.pem` -> Host Private Key
#         * `<fqdn>.pub` -> Host Public Key
#
# If $pki is set to 'simp', the keydist directory will have the same structure,
# however it will be located in a separate module path so keys don't get clobbered
# when using r10k:
# * `/var/simp/environments/${environment}/site_files/pki_files/files/keydist`
#
# @param pki
#   * If 'simp', certs will be copied from `puppet:///modules/pki_files/keydist`
#
#   * If true or false, certs will be copied from `puppet:///modules/${module_name}/keydist`
#
# @param base
#   The  directory to which certs will be copied.
#
# @param certname
#   The name of the cert to be used on this host
#
#   Defaults to the Puppet certname.
#
# @param private_key_source
#   The source of the private key content
#
#   * This parameter accepts the same values as the `file` type's `source`
#     parameter
#
# @param public_key_source
#   The source of the private key content
#
#   * This parameter accepts the same values as the `file` type's `source`
#     parameter
#
# @param auditd
#   Whether or not to enable auditing of the system keys
#
# @param sync_purge
#   Whether or not the PKI sync type should purge the destination directory
#
#   * If set to `true` (the default), the `/etc/pki/cacerts` directory
#     will have any non-recognized certificates removed.
#
# @param cacerts_sources
#   Modulepath to look in for the CA certs. Normally this is a special
#   modulepath outside of the normal $codedir. The full path can be found
#   in the `environment.conf` or through `puppet config print modulepath`
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class pki (
  Variant[Boolean,Enum['simp']] $pki                = simplib::lookup('simp_options::pki', { 'default_value' => 'simp' }),
  Stdlib::Absolutepath          $base               = simplib::lookup('simp_options::pki::source', { 'default_value' => '/etc/pki/simp/x509' }),
  String                        $certname           = pick($trusted['certname'], $facts['fqdn']),
  String                        $private_key_source = "puppet:///modules/${module_name}/keydist/${certname}/${certname}.pem",
  String                        $public_key_source  = "puppet:///modules/${module_name}/keydist/${certname}/${certname}.pub",
  Boolean                       $auditd             = simplib::lookup('simp_options::auditd', { 'default_value' => false}),
  Boolean                       $sync_purge         = true,
  Array[String]                 $cacerts_sources    = [
    "puppet:///modules/${module_name}/keydist/cacerts",
    "puppet:///modules/${module_name}/keydist/cacerts/${certname}/cacerts"
  ]
) {

  if $pki == 'simp' {
    file { '/etc/pki/simp':
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0655',
      tag    => 'firstrun',
    }

    $_private_key_source = "puppet:///modules/pki_files/keydist/${certname}/${certname}.pem"
    $_public_key_source  = "puppet:///modules/pki_files/keydist/${certname}/${certname}.pub"
    $_cacerts_sources    = [
      'puppet:///modules/pki_files/keydist/cacerts',
      "puppet:///modules/pki_files/keydist/cacerts/${certname}/cacerts"
    ]
  }
  else {
    $_private_key_source = $private_key_source
    $_public_key_source  = $public_key_source
    $_cacerts_sources    = $cacerts_sources
  }

  # These are for reference by other modules and provide a consistent interface
  # for future updates.
  $private_key_dir = "${base}/private"
  $public_key_dir  = "${base}/public"
  $private_key     = "${private_key_dir}/${certname}.pem"
  $public_key      = "${public_key_dir}/${certname}.pub"
  $cacerts         = "${base}/cacerts"
  $cacertfile      = "${base}/cacerts/cacerts.pem"

  if $auditd {
    include '::auditd'

    # Add audit rules for PKI key material
    auditd::rule { 'pki':
      content => "-w ${base} -p wa -k PKI"
    }
  }

  $_base_require = $pki ? { 'simp' => File['/etc/pki/simp'], default => undef }
  file { $base:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0655',
    tag     => 'firstrun',
    require => $_base_require
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
    source    => $_private_key_source,
    tag       => 'firstrun',
    seltype   => 'cert_t',
    show_diff => false
  }

  file { $public_key:
    owner     => 'root',
    group     => 'root',
    mode      => '0444',
    source    => $_public_key_source,
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
    source       => $_cacerts_sources,
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
