# Reference

## Classes
* [`pki`](#pki): This class provides the capability to manage non-Puppet PKI keys that are hosted on the Puppet server.  The keydist directory must have the f
* [`pki::copy::apps_dir`](#pkicopyapps_dir): **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**  This class configures the top-level appl
## Defined types
* [`pki::copy`](#pkicopy): This Defined Type provides a useful copy function for properly copying the entire set of SIMP-based PKI certificates as deployed by the PKI m
## Resource types
* [`pki_cert_sync`](#pki_cert_sync): A puppet type for merging the contents of one directory full of X.509 PKI certificates into another while hashing the certificates in a manne
## Classes

### pki

This class provides the capability to manage non-Puppet PKI keys that are
hosted on the Puppet server.

The keydist directory must have the following structure:

* `${codedir}/${environment}/modules/#{module_name}/files/keydist/`
    * `cacerts`
        * Any X.509 PEM formatted CA certificates that you want to serve to
          your clients.
    * `<fqdn>`
        * `cacerts`
            * Any X.509 PEM formatted CA certificates that you want to serve
              to this particular client.
        * `<fqdn>.pem` -> Host Private Key
        * `<fqdn>.pub` -> Host Public Key

If $pki is set to 'simp', the keydist directory will have the same structure,
however it will be located in a separate module path so keys don't get clobbered
when using r10k:
* `/var/simp/environments/${environment}/site_files/pki_files/files/keydist`


#### Parameters

The following parameters are available in the `pki` class.

##### `pki`

Data type: `Variant[Boolean,Enum['simp']]`

* If 'simp', certs will be copied from `puppet:///modules/pki_files/keydist`

* If true or false, certs will be copied from `puppet:///modules/${module_name}/keydist`

Default value: simplib::lookup('simp_options::pki', { 'default_value' => 'simp' })

##### `base`

Data type: `Stdlib::Absolutepath`

The  directory to which certs will be copied.

Default value: simplib::lookup('simp_options::pki::source', { 'default_value' => '/etc/pki/simp/x509' })

##### `certname`

Data type: `String`

The name of the cert to be used on this host

Defaults to the Puppet certname.

Default value: pick($trusted['certname'], $facts['fqdn'])

##### `private_key_source`

Data type: `String`

The source of the private key content

* This parameter accepts the same values as the `file` type's `source`
  parameter

Default value: "puppet:///modules/${module_name}/keydist/${certname}/${certname}.pem"

##### `public_key_source`

Data type: `String`

The source of the private key content

* This parameter accepts the same values as the `file` type's `source`
  parameter

Default value: "puppet:///modules/${module_name}/keydist/${certname}/${certname}.pub"

##### `auditd`

Data type: `Boolean`

Whether or not to enable auditing of the system keys

Default value: simplib::lookup('simp_options::auditd', { 'default_value' => false})

##### `sync_purge`

Data type: `Boolean`

Whether or not the PKI sync type should purge the destination directory

* If set to `true` (the default), the `/etc/pki/cacerts` directory
  will have any non-recognized certificates removed.

Default value: `true`

##### `cacerts_sources`

Data type: `Array[String]`

Module path to look in for the CA certs

Default value: [
    "puppet:///modules/${module_name}/keydist/cacerts",
    "puppet:///modules/${module_name}/keydist/cacerts/${certname}/cacerts"
  ]


### pki::copy::apps_dir

**NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**

This class configures the top-level application directory where
application-level copies of PKI keys will be housed


#### Parameters

The following parameters are available in the `pki::copy::apps_dir` class.

##### `target`

Data type: `Stdlib::Absolutepath`

The name of the destination directory

Default value: '/etc/pki/simp_apps'

##### `purge`

Data type: `Boolean`

Whether or not to purge unmanaged keys from the directory

* NOTE: It is **highly recommended** that you purge unmanaged keys for
  security reasons

Default value: `true`


## Defined types

### pki::copy

This Defined Type provides a useful copy function for properly copying the
entire set of SIMP-based PKI certificates as deployed by the PKI module to a
different location.

This is particularly important when dealing with SELinux enabled services
since they tend to react poorly to symlinks.


#### Parameters

The following parameters are available in the `pki::copy` defined type.

##### `pki`

Data type: `Variant[Boolean,Enum['simp']]`

* If set to `simp` or `true`
  * Certificates will be centralized in /etc/pki/simp_apps/, and copied to
    `/etc/pki/simp_apps/$name/x509`.

* If set to `simp`
  * Include the `pki` class

* If set to `false`
  * Certificates will *not* be centralized, and you must provide a `$destination`

Default value: simplib::lookup('simp_options::pki', { 'default_value' => false})

##### `name`

Data type: `Variant[String,Stdlib::Absolutepath]`

* If `$pki = true` or `$pki = 'simp'` this parameter will be used to namespace
  certificates in `/etc/pki/simp_apps/$name/x509`.

* If `$pki = false`, this variable has no effect.

##### `source`

Data type: `String`

Where to find the certificates. This value could be one of a few types:
  * Absolute path
  * A file URL in the form of `(https|puppet):///file/path`. See the `file`
    resource documentation for details on the format of this URL
  * An NSS database. This must be managed by something else, like IPA.

If the setting is a path (file or URL), the locations referenced must have
the following structure:
  * `<path>/cacerts`
  * `<path>/private`
  * `<path>/public`

  * **NOTE:** No other directories will be copied!

Default value: simplib::lookup('simp_options::pki::source', { 'default_value' => '/etc/pki/simp/x509' })

##### `destination`

Data type: `Optional[Stdlib::Absolutepath]`

Optional. The destination that PKI certs get copied to.

  * If `$pki = false`:
    * You *must* specify $destination.
    * You will need to ensure that all parent directories have been
      properly created.
    * A 'pki' directory will be created under this space
      * For example, if you set this to `/foo/bar` then `/foo/bar/pki`
        will be created

  * If `$pki = true` or `$pki = 'simp'`:
    * This variable has no effect.

Default value: `undef`

##### `owner`

Data type: `String`

The owner of the directories/files that get copied

Default value: 'root'

##### `group`

Data type: `String`

The group of the directories/files that get copied

Default value: 'root'


## Resource types

### pki_cert_sync

A puppet type for merging the contents of one directory full of X.509 PKI
certificates into another while hashing the certificates in a manner
appropriate for use by most Linux applications (Apache, OpenLDAP, etc...).

Usage:

pki_cert_sync { '<target_dir>': source => '<source_dir>' }

Both directories must exist on the local operating system, remote file
syncing is not supported. File attributes will all be copied from the
source directory.

Any SELinux contexts will be preserved on existing files and copied from
the source files if the destination file does not exist.


#### Properties

The following properties are available in the `pki_cert_sync` type.

##### `source`



#### Parameters

The following parameters are available in the `pki_cert_sync` type.

##### `name`

namevar



##### `purge`

Valid values: `true`, `false`



Default value: `true`


