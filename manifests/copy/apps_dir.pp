# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# This class configures the top-level application directory where
# application-level copies of PKI keys will be housed
#
# @param target
#   The name of the destination directory
#
# @param purge
#   Whether or not to purge unmanaged keys from the directory
#
#   * NOTE: It is **highly recommended** that you purge unmanaged keys for
#     security reasons
class pki::copy::apps_dir (
  Stdlib::Absolutepath $target              = '/etc/pki/simp_apps',
  Boolean              $purge               = true
){
  assert_private()

  file { $target:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    recurse => $purge,
    purge   => $purge,
    force   => $purge
  }
}
