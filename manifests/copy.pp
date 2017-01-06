# This Defined Type provides a useful copy function for properly copying the
# entire set of SIMP-based PKI certificates as deployed by the PKI module to a
# different location.
#
# This is particularly important when dealing with SELinux enabled services
# since they tend to react poorly to symlinks.
#
# @param name [Variant[String,Stdlib::Absolutepath]]
#
#   * If $pki = true or $pki = 'simp' this parameter will be used to namespace
#     certificates in /etc/pki/simp_apps/$name.
#
#   * If $pki = false, this variable has no effect.
#
# @param source
#   The path to the PKI directory that you wish to copy
#
#     * This must have the following structure:
#         * ``<path>/cacerts``
#         * ``<path>/private``
#         * ``<path>/public``
#
#     * **NOTE:** No other directories will be copied!
#
# @param destination
#   Optional. The destination that PKI certs get copied to.
#
#     * If $pki = false:
#       * You *must* specify $destination.
#       * You will need to ensure that all parent directories have been properly
#         created
#       * A 'pki' directory will be created under this space
#         * For example, if you set this to ``/foo/bar`` then ``/foo/bar/pki``
#           will be created
#
#     * If $pki = true or 'simp':
#       * This variable has no effect.
#
# @param owner
#   The owner of the directories/files that get copied
#
# @param group
#   The group of the directories/files that get copied
#
# @param pki
#
#   * If set to ``simp`` or ``true``
#     * Certificates will be centralized in /etc/pki/simp_apps/, and copied to
#       /etc/pki/simp_apps/$name/pki.
#
#   * If set to ``simp``
#     * Include the ``::pki`` class
#
#   * If set to ``false``
#     * Certificates will *not* be centralized, and you must provide a $destination.
#
# @author Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
define pki::copy (
  Stdlib::Absolutepath           $source      = simplib::lookup('simp_options::pki::source', { 'default_value' => '/etc/pki/simp' }),
  Optional[Stdlib::Absolutepath] $destination = undef,
  String                         $owner       = 'root',
  String                         $group       = 'root',
  Variant[Boolean,Enum['simp']]  $pki         = simplib::lookup('simp_options::pki', { 'default_value' => false}),
) {

  if !$pki {
    if !$destination {
      fail('You must specify a $destination if $pki false.')
    }
    else {
      $_destination = $destination
    }
  }
  else {
    if $destination {
      notify { "pki_copy_${name}":
        message => "Pki is managing cert destination. Ignoring specified destination ${destination}"
      }
    }

    # Only ensure this directory exists if pki is true or 'simp'.
    # There is a reasonable expectation if users have pki globally
    # disabled, they do not intend to use this directory for cert
    # centralization.
    ensure_resource('file', '/etc/pki/simp_apps', {
      'ensure' => 'directory',
      'owner'  => 'root',
      'group'  => 'root',
      'mode'   => '0640'}
    )

    $_destination = "/etc/pki/simp_apps/${name}"
    file { $_destination:
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0640'
    }

    if $pki == 'simp' {
      include '::pki'
      Class['pki'] -> Pki::Copy[$name]
    }
  }

  file { "${_destination}/pki":
    ensure => 'directory',
    owner  => $owner,
    group  => $group,
    mode   => '0640'
  }

  file { "${_destination}/pki/public":
    ensure    => 'directory',
    owner     => $owner,
    group     => $group,
    mode      => '0640',
    recurse   => true,
    source    => "${source}/public",
    seltype   => 'cert_t',
    show_diff => false
  }

  file { "${_destination}/pki/private":
    ensure    => 'directory',
    owner     => $owner,
    group     => $group,
    mode      => '0640',
    recurse   => true,
    source    => "${source}/private",
    seltype   => 'cert_t',
    show_diff => false
  }

  file { "${_destination}/pki/cacerts":
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
