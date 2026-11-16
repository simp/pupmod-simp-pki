require 'spec_helper'

shared_examples_for 'pki = simp', :compile do
  it { is_expected.to create_class('pki') }
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_file('/etc/pki/simp').with_ensure('directory') }
  it { is_expected.to create_file('/etc/pki/simp/x509').with_ensure('directory') }
  it { is_expected.to create_file('/etc/pki/simp/x509/private').with_ensure('directory').without_purge.without_recurse }
  it { is_expected.to create_file('/etc/pki/simp/x509/public').with_ensure('directory').without_purge.without_recurse }

  it {
    is_expected.to create_file('/etc/pki/simp/x509/private/test.example.domain.pem')
      .with_source('puppet:///modules/pki_files/keydist/test.example.domain/test.example.domain.pem')
  }

  it {
    is_expected.to create_file('/etc/pki/simp/x509/public/test.example.domain.pub')
      .with_source('puppet:///modules/pki_files/keydist/test.example.domain/test.example.domain.pub')
  }

  it { is_expected.to create_file('/etc/pki/simp/x509/cacerts').with_ensure('directory') }
end

describe 'pki' do
  on_supported_os.each do |os, os_facts|
    let(:facts) do
      os_facts[:networking][:fqdn] = 'test.example.domain'
      os_facts
    end
    let(:node) { 'test.example.domain' }

    context "on #{os}" do
      context 'with default parameters' do
        it { is_expected.not_to contain_class('auditd') }
        it_behaves_like 'pki = simp'
      end

      context 'with auditd => true' do
        let(:params) { { auditd: true } }

        it { is_expected.to contain_class('auditd') }
        it_behaves_like 'pki = simp'
      end

      context 'with purge_key_dirs => true and both keys on the server' do
        let(:params) { { purge_key_dirs: true } }

        it { is_expected.to compile.with_all_deps }

        ['private', 'public'].each do |dir|
          it {
            is_expected.to create_file("/etc/pki/simp/x509/#{dir}")
              .with_recurse(true).with_purge(true).with_force(true).with_backup(false)
          }
        end
      end

      context 'with purge_key_dirs => true and no keys on the server for this certname' do
        let(:params) { { purge_key_dirs: true, certname: 'missing.example.domain' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_file('/etc/pki/simp/x509/private').without_purge.without_recurse }
        it { is_expected.to create_file('/etc/pki/simp/x509/public').without_purge.without_recurse }
      end

      context 'with purge_key_dirs => true and key sources that cannot be checked' do
        let(:params) do
          {
            purge_key_dirs: true,
            pki: false,
            private_key_source: 'https://keys.example.domain/test.example.domain.pem',
            public_key_source: 'https://keys.example.domain/test.example.domain.pub',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_file('/etc/pki/simp/x509/private').without_purge.without_recurse }
        it { is_expected.to create_file('/etc/pki/simp/x509/public').without_purge.without_recurse }
      end

      [true, false].each do |pki|
        context "with pki => #{pki}" do
          let(:params) { { pki: pki } }

          it { is_expected.to create_file('/etc/pki/simp').with_ensure('directory') }
          it { is_expected.to create_file('/etc/pki/simp/x509/private/test.example.domain.pem').with_source('puppet:///modules/pki/keydist/test.example.domain/test.example.domain.pem') }
          it { is_expected.to create_file('/etc/pki/simp/x509/public/test.example.domain.pub').with_source('puppet:///modules/pki/keydist/test.example.domain/test.example.domain.pub') }
          it { is_expected.to create_file('/etc/pki/simp/x509/cacerts').with_ensure('directory') }
        end
      end
    end
  end
end
