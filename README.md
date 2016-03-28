[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html) [![Build Status](https://travis-ci.org/simp/pupmod-simp-pki.svg)](https://travis-ci.org/simp/pupmod-simp-pki) [![SIMP compatibility](https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg)](https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg)

# simp-pki

#### Table of Contents

1. [Description](#description)
   * [This is a SIMP module](#this-is-a-simp-module)
2. [Setup - The basics of getting started with simp-pki](#setup)
    * [What simp-pki affects](#what-simp-pki-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with simp-pki](#beginning-with-simp-pki)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

This module provides the capability to manage non-Puppet PKI keys that are
hosted on the Puppet server. It requires keys to be managed under the PKI
module at `${environmant}/modules/pki/files/keydist`.

The `keydist` directory must have the following structure:

```
${environment}/modules/pki/files/keydist/
  - cacerts
    - Any X.509 PEM formatted CA certificates that you want to serve to your
      clients. Do NOT hash these certificates. This will be done on the client
      side.
  - <fqdn>
    - cacerts
      - Any X.509 PEM formatted CA certificates that you want to serve to your
        clients. Do NOT hash these certificates. This will be done on the
        client side.
    - <fqdn>.pem -> Client Private Key
    - <fqdn>.pub -> Client Public Key
```


### This is a SIMP module

This module is a component of the
[System Integrity Management Platform](https://github.com/NationalSecurityAgency/SIMP),
a compliance-management framework built on Puppet.

If you find any issues, they can be submitted to our
[JIRA](https://simp-project.atlassian.net/) or you can find us on
[HipChat](https://www.hipchat.com/ggkCeNuLk).

## Setup

### What simp-pki affects

This module both adds your client X.509 PKI keys to the system at
`/etc/pki/{cacerts,private,public}` and provides the ability to copy those
certificates (or other certificates in the same directory format) into
application spaces.

### Setup Requirements

The main functionality of this module is supported by the use of a Puppet
Server. However, the `pki::copy` functionality may be used without connectivity
to the Puppet Server.

To use the server side functionality, you **must** have a special `keydist`
Puppet share.

The following is the recommended addition to `auth.conf` for realizing this share:

```
# Everyone gets access to the cacerts and mcollective
path ~ ^/file_(metadata|content)/modules/pki/keydist/cacerts
allow *


# Allow access to the keydist space for only the nodes that match via
# certificate name
path ~ ^/file_(metadata|content)/modules/pki/keydist/([^/]+)
allow $2
```

### Beginning with simp-pki

## Usage

To sync certificates to your system, simply include the `pki` class.

```
include '::pki'
```

To copy the certificates into your application space, use the `pki::copy`
define.

This will **automatically** include the simp-pki class unless told otherwise.

```
pki::copy { '/etc/httpd': }
```

This will result in the directory `/etc/httpd/pki` being created with the
`cacerts`, `public`, and `private` subdirectories as specified in the `keydist`
directory.

## Development

Please read our
[Contribution Guide](https://simp-project.atlassian.net/wiki/display/SD/Contributing+to+SIMP)
and visit our
[developer wiki](https://simp-project.atlassian.net/wiki/display/SD/SIMP+Development+Home).
