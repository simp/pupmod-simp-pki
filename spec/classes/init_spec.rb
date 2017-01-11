require 'spec_helper'

describe 'pki' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts.merge( { :fqdn => 'test.example.domain' } )
      end

      context 'with default parameters' do
        it { is_expected.to create_class('pki') }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to_not contain_class('auditd') }

        it { is_expected.to create_file('/etc/pki/simp').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/simp/private').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/simp/public').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/simp/private/test.example.domain.pem') \
          .with_source('puppet:///modules/pki_files/keydist/test.example.domain/test.example.domain.pem') }
        it { is_expected.to create_file('/etc/pki/simp/public/test.example.domain.pub') \
          .with_source('puppet:///modules/pki_files/keydist/test.example.domain/test.example.domain.pub') }
        it { is_expected.to create_file('/etc/pki/simp/cacerts').with_ensure('directory') }
      end

      context 'with auditd => true' do
        let(:params){{ :auditd => true }}

        it { is_expected.to contain_class('auditd') }
        it { is_expected.to create_file('/etc/pki/simp').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/simp/private').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/simp/public').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/simp/private/test.example.domain.pem') }
        it { is_expected.to create_file('/etc/pki/simp/public/test.example.domain.pub') }
        it { is_expected.to create_file('/etc/pki/simp/cacerts').with_ensure('directory') }
      end

      [true,false].each do |pki|
        context "with pki => #{pki}" do
          let(:params) {{ :pki => pki }}

          it { is_expected.to create_file('/etc/pki/simp/private/test.example.domain.pem').with_source('puppet:///modules/pki/keydist/test.example.domain/test.example.domain.pem') }
          it { is_expected.to create_file('/etc/pki/simp/public/test.example.domain.pub').with_source('puppet:///modules/pki/keydist/test.example.domain/test.example.domain.pub') }
          it { is_expected.to create_file('/etc/pki/simp/cacerts').with_ensure('directory') }
        end
      end

    end
  end
end
