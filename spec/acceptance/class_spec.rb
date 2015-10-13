require 'spec_helper_acceptance'

test_name 'pki_sync'

describe 'pki_sync' do

  let(:manifest) {
  <<-EOS
  file { '/etc/pki/cacerts':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    seltype => 'cert_t',
    recurse => true,
    tag     => 'firstrun'
  }
  pki_cert_sync { '/etc/pki/cacerts':
    source => '/etc/pki/simp-testing/pki/cacerts/',
    purge  => true,
  }
  EOS
  }

  let(:no_purge_manifest) {
  <<-EOS
  file { '/etc/pki/cacerts':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    seltype => 'cert_t',
    recurse => true,
    tag     => 'firstrun'
  }
  pki_cert_sync { '/etc/pki/cacerts':
    source => '/etc/pki/simp-testing/pki/cacerts/',
    purge => false
  }  
  EOS
  }

  hosts.each do |host|

    # Generate and copy over some cacerts
    run_fake_pki_ca_on(host, host)
    copy_keydist_to(host, '/root/keydist1')
    run_fake_pki_ca_on(host, host)
    copy_keydist_to(host, '/root/keydist2')

    # Create a subdirectory in simp-testing/pki/cacerts, and copy over the newly
    # created CA.
    on host, "mkdir -p /etc/pki/simp-testing/pki/cacerts/some/subdirectory"
    on host, "cp /root/keydist1/cacerts/*.pem /etc/pki/simp-testing/pki/cacerts/some/subdirectory"
    on host, "chgrp -R puppet /etc/pki/simp-testing/"

    context 'default parameters (purge = true)' do

      #
      # Given default params and one cert: expect the cert to be synced, a symlink
      # created for it, and its contents added to cacerts.pem
      #
      it 'should work with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      describe file('/etc/pki/cacerts/') {
        it { is_expected.to be_file }
      }

      it 'the cacert should be synced' do
        on host, "cmp $(find /etc/pki/simp-testing/pki/cacerts/some/subdirectory/ /etc/pki/cacerts/some/subdirectory/ -name cacert_*.pem)", :acceptable_exit_codes => [0]
      end

      it 'a link to the cert should be created at the top level' do
        on host, "ls -l /etc/pki/cacerts/ | grep $(ls /etc/pki/cacerts/some/subdirectory/ | grep .pem)", :acceptable_exit_codes => [0]
      end

      it 'the cert should be appended to cacerts.pem' do
        on host, "grep $(sed 's/^-.*//g' /etc/pki/cacerts/some/subdirectory/*.pem | tr -d '\n') <<< $(sed 's/^-.*//g' /etc/pki/cacerts/cacerts.pem | tr -d '\n')", :acceptable_exit_codes => [0]
      end

      #
      # If a CA cert is added to the top level while purge=true,  expect
      # it to be removed.
      #
      it 'copy non synced cert into /etc/pki/cacerts' do
        on host, "cp /root/keydist2/cacerts/*.pem /etc/pki/cacerts"
      end

      it 'should purge non synced certs' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'the purged file should not exist' do
        on host, "[[ -f /etc/pki/cacerts/$(ls /root/keydist2/cacerts/ | grep .pem) ]]", :acceptable_exit_codes => [1]
      end

      #
      # If a malformed cert is added to the sync directory, it should not be synced.
      #
      #
      it 'generate malformed cert in /etc/pki/simp-testing/pki/cacerts' do
        on host, "touch /etc/pki/simp-testing/pki/cacerts/foofile"
      end

      it 'sync should not copy malformed cert' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'malformed cert should not exist in /etc/pki/cacerts' do
        on host, "[[ -f /etc/pki/cacerts/foofile ]]", :acceptable_exit_codes => [1]
      end

      it 'remove malformed cert from sync directory' do
        on host, "rm -f /etc/pki/simp-testing/pki/cacerts/foofile"
      end

      #
      # If a cacert is removed from the sync directory, it should be purged, but
      # any residual directory structure should remain.
      #
      it 'removing /etc/pki/simp-testing/pki/cacerts/some/subdirectory/*.pem' do
        on host, "rm -f /etc/pki/simp-testing/pki/cacerts/some/subdirectory/*.pem"
      end

      it 'purge deleted cert' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'deleted cert should be removed from sync directory' do
        on host, "ls -A /etc/pki/cacerts/some/subdirectory/ | grep pem", :acceptable_exit_codes => [1]
      end

      it 'but the directory should still exist' do
        on host, "ls -A /etc/pki/cacerts/some/subdirectory", :acceptable_exit_codes => [0]
      end
    end

    #
    # Set purged = false.  If a cert is copied into /etc/pki/cacerts, it
    # should exist after puppet apply.
    #
    context 'with purge = false' do
      it 'copy non synced cert into /etc/pki/cacerts' do
        on host, "cp /root/keydist2/cacerts/*.pem /etc/pki/cacerts"
      end

      it 'should not purge non-synced cert' do
        apply_manifest_on(host, no_purge_manifest, :catch_failures => true)
      end

      it 'the purged file should not exist' do
        on host, "[[ -f /etc/pki/cacerts/$(ls /root/keydist2/cacerts/ | grep .pem) ]]", :acceptable_exit_codes => [0]
      end
    end
  end
end
