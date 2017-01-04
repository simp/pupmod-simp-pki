# This Defined Type provides a useful copy function for properly copying the
# entire set of SIMP-based PKI certificates as deployed by the PKI module to a
# different location.
#
# This is particularly important when dealing with SELinux enabled services
# since they tend to react poorly to symlinks.
#
# @param name [Stdlib::Absolutepath]
#   The path to the directory where the certificates will be housed
#
#   * You will need to ensure that all parent directories have been properly
#     created
#
#   * A 'pki' directory will be created under this space
#       * For example, if you set this to ``/foo/bar`` then ``/foo/bar/pki``
#         will be created
#
# @param source
#   The path to the PKI directory that you wish to copy
#
#   * This must have the following structure:
#       * ``<path>/cacerts``
#       * ``<path>/private``
#       * ``<path>/public``
#
#   * **NOTE:** No other directories will be copied!
#
# @param owner
#   The owner of the directories/files that get copied
#
# @param group
#   The group of the directories/files that get copied
#
# @param pki
#   If set to ``simp`` it will include the ``::pki`` class to copy certs from
#   the puppet server to ``$::pki::pki_dir``
#
# @author Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
define pki::copy (
  Stdlib::Absolutepath          $source = simplib::lookup('simp_options::pki::source', { 'default_value' => '/etc/pki/simp' }),
  String                        $owner  = 'root',
  String                        $group  = 'root',
  Variant[Boolean,Enum['simp']] $pki    = simplib::lookup('simp_options::pki', { 'default_value' => false}),
) {

  if $pki == 'simp' {
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
    ensure    => 'directory',
    owner     => $owner,
    group     => $group,
    mode      => '0640',
    recurse   => true,
    source    => "${source}/public",
    seltype   => 'cert_t',
    show_diff => false
  }

  file { "${name}/pki/private":
    ensure    => 'directory',
    owner     => $owner,
    group     => $group,
    mode      => '0640',
    recurse   => true,
    source    => "${source}/private",
    seltype   => 'cert_t',
    show_diff => false
  }

  file { "${name}/pki/cacerts":
    ensure    => 'directory',
    owner     => $owner,
    group     => $group,
    mode      => '0640',
    recurse   => true,
    source    => "${source}/cacerts",
    seltype   => 'cert_t',
    show_diff => false
  }
}
