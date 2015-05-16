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
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
define pki::copy (
  $owner = 'root',
  $group = 'root'
) {
  include '::pki'

  file { "${name}/pki":
    ensure  => 'directory',
    owner   => $owner,
    group   => $group,
    mode    => '0640'
  }

  file { "${name}/pki/public":
    ensure  => 'directory',
    owner   => $owner,
    group   => $group,
    mode    => '0640',
    recurse => true,
    source  => '/etc/pki/public',
    require => Class['pki']
  }

  file { "${name}/pki/private":
    ensure  => 'directory',
    owner   => $owner,
    group   => $group,
    mode    => '0640',
    recurse => true,
    source  => '/etc/pki/private',
    require => Class['pki']
  }

  file { "${name}/pki/cacerts":
    ensure  => 'directory',
    owner   => $owner,
    group   => $group,
    mode    => '0640',
    seltype => 'cert_t',
    recurse => true,
    source  => '/etc/pki/cacerts',
    require => Class['pki']
  }
}
