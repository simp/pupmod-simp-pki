# == Define: pki::copy
#
# This define provides a useful copy function for properly copying the entire
# set of SIMP-based PKI certificates as deployed by the PKI module to a
# different location.
#
# This is particularly important when dealing with SELinux enabled services
# since they tend to react poorly to symlinks.
#
# == Parameters
#
# [*name*]
# Type: Absolute Path
#   This is the path to the name directory where the certificates will be
#   housed. You will need to ensure that all parent directories have been
#   properly created.
#
#   A 'pki' directory will be created under this space.
#
#   Example:
#   $name = '/foo/bar'
#
#   Created directory => /foo/bar/pki
#
# [*source*]
# Type: Absolute Path
# Default: '/etc/pki'
#   The path to the PKI directory that you wish to copy. This should have the following structure:
#     * <path>/cacerts
#     * <path>/private
#     * <path>/public
#
#   NOTE: No other directories will be copied!
#
# [*owner*]
# Type: String
# Default: root
#   The owner of the directories/files that get copied.
#
# [*group*]
# Type: String
# Default: root
#   The group of the directories/files that get copied.
#
# [*use_simp_pki*]
# Type: Boolean
# Default: true
#   If true, use the SIMP PKI stack for certificate management.
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
define pki::copy (
  $source = '/etc/pki',
  $owner = 'root',
  $group = 'root',
  $use_simp_pki = defined('$::use_simp_pki') ? { true => $::use_simp_pki, default => hiera('use_simp_pki', true) }
) {
  validate_absolute_path($source)
  validate_string($owner)
  validate_string($group)
  validate_bool($use_simp_pki)

  if $use_simp_pki {
    include '::pki'

    Class['pki'] -> Pki::Copy[$name]
  }

  file { "${name}/pki":
    ensure => 'directory',
    owner  => $owner,
    group  => $group,
    mode   => '0640'
  }

  file { "${name}/pki/public":
    ensure  => 'directory',
    owner   => $owner,
    group   => $group,
    mode    => '0640',
    recurse => true,
    source  => "${source}/public"
  }

  file { "${name}/pki/private":
    ensure  => 'directory',
    owner   => $owner,
    group   => $group,
    mode    => '0640',
    recurse => true,
    source  => "${source}/private"
  }

  file { "${name}/pki/cacerts":
    ensure  => 'directory',
    owner   => $owner,
    group   => $group,
    mode    => '0640',
    seltype => 'cert_t',
    recurse => true,
    source  => "${source}/cacerts"
  }
}
