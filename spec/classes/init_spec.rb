require 'spec_helper'

shared_examples_for 'pki = simp', :compile do
  it { is_expected.to create_class('pki') }
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_file('/etc/pki/simp').with_ensure('directory') }
  it { is_expected.to create_file('/etc/pki/simp/x509').with_ensure('directory') }
  it { is_expected.to create_file('/etc/pki/simp/x509/private').with_ensure('directory') }
  it { is_expected.to create_file('/etc/pki/simp/x509/public').with_ensure('directory') }

  it {
    is_expected.to create_file('/etc/pki/simp/x509/private/test.example.domain.pem') \
      .with_source('puppet:///modules/pki_files/keydist/test.example.domain/test.example.domain.pem')
  }

  it {
    is_expected.to create_file('/etc/pki/simp/x509/public/test.example.domain.pub') \
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

      [true, false].each do |pki|
        context "with pki => #{pki}" do
          let(:params) { { pki: pki } }

          it { is_expected.to create_file('/etc/pki/simp/x509/private/test.example.domain.pem').with_source('puppet:///modules/pki/keydist/test.example.domain/test.example.domain.pem') }
          it { is_expected.to create_file('/etc/pki/simp/x509/public/test.example.domain.pub').with_source('puppet:///modules/pki/keydist/test.example.domain/test.example.domain.pub') }
          it { is_expected.to create_file('/etc/pki/simp/x509/cacerts').with_ensure('directory') }
        end
      end
    end
  end
end
