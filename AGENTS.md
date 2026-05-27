# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Commands

Install dependencies:
```bash
bundle install
```

Run all spec tests:
```bash
bundle exec rake spec
```

Run a single spec test file:
```bash
bundle exec rspec spec/classes/init_spec.rb
bundle exec rspec spec/unit/puppet/provider/pki_cert_sync/sync_spec.rb
```

Puppet syntax and lint checks:
```bash
bundle exec rake syntax
bundle exec rake lint
bundle exec rake metadata_lint
```

Ruby style check:
```bash
bundle exec rake rubocop
```

Generate REFERENCE.md from Puppet Strings:
```bash
bundle exec rake strings:generate:reference
```

## Architecture

This is a SIMP Puppet module (`simp/pki`) for managing non-Puppet PKI keys and certificates on managed nodes. It targets RHEL/CentOS/Rocky/AlmaLinux 7–9, Puppet 7–8.

### Key components

**`manifests/init.pp` — `pki` class**
The main class that syncs PKI certificates from a Puppet fileserver to the node at `/etc/pki/simp/x509/{cacerts,private,public}`. It uses an intermediate staging directory (`$base/.cacerts_ingress`) to receive CA certs from the Puppet server, then delegates to `pki_cert_sync` to hash and install them into the final `cacerts/` location.

The `$pki` parameter controls the certificate source:
- `'simp'` (default): reads from `puppet:///modules/pki_files/keydist/` (a separate module path that survives r10k deploys)
- `true`/`false`: reads from `puppet:///modules/pki/keydist/` (the module's own files directory)

**`manifests/copy.pp` — `pki::copy` defined type**
Copies the full `{cacerts,private,public}` subtree from a source path into an application-specific directory. When `$pki` is `true`/`'simp'`, the destination is namespaced under `/etc/pki/simp_apps/$name/x509`. When `$pki` is `false`, a caller-supplied `$destination` is required.

**`lib/puppet/type/pki_cert_sync.rb` — `pki_cert_sync` custom type**
A Puppet resource type that compares a source directory of X.509 PEM certificates against a target directory. The namevar is the target directory path; `:source` is the source directory path.

**`lib/puppet/provider/pki_cert_sync/sync.rb` — `redhat` provider**
Implements the `pki_cert_sync` type. Core operations:
- `source`: scans the source directory, generates `{pem_file => hash_link}` pairs using OpenSSL to compute subject hashes, and builds aggregate `cacerts.pem` / `cacerts_no_headers.pem` reference files in tempfiles.
- `source_insync?`: compares source state against target directory; checks file counts, directory trees, content, and symlinks.
- `source=`: performs the actual sync — purges stale files, copies PEM files, creates `<hash>.N` symlinks, and syncs the aggregate cacerts files. Preserves SELinux contexts on all files.

### Certificate flow

```
Puppet fileserver (keydist/)
        ↓ file resource (recursive)
$base/.cacerts_ingress/    ← staging area
        ↓ pki_cert_sync resource
$base/cacerts/             ← hashed CA certs (cacerts.pem, cacerts_no_headers.pem, <hash>.N symlinks)
$base/private/             ← host private key
$base/public/              ← host public key
```

### keydist directory structure

The Puppet fileserver share `keydist/` must follow this layout:
```
keydist/
  cacerts/               ← global CA certs (served to all nodes)
    cacerts/<fqdn>/cacerts/  ← per-node CA certs (optional)
  <fqdn>/
    <fqdn>.pem           ← node private key
    <fqdn>.pub           ← node public key
```

### Test structure

- `spec/classes/init_spec.rb` — rspec-puppet catalog tests for the `pki` class
- `spec/defines/copy_spec.rb` — rspec-puppet catalog tests for `pki::copy`
- `spec/unit/puppet/provider/pki_cert_sync/sync_spec.rb` — unit tests for the Ruby provider using real tempfiles and OpenSSL
- `spec/unit/puppet/type/pki_cert_sync_spec.rb` — unit tests for the custom type

Test fixtures are declared in `.fixtures.yml` and pulled from GitHub (simplib, stdlib, auditd, augeasproviders).

Set `PUPPET_DEBUG=1` to enable Puppet debug logging in spec tests. Set `PUPPET_VERSION` to `~> 7.0` or `~> 8.0` to control which Puppet gem version is used.
