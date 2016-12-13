require 'spec_helper'

describe 'pki' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts.merge( { :fqdn => 'test.example.domain' } )
      end

      it { is_expected.to create_class('pki') }

      context 'base' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to_not contain_class('auditd') }
    
        it { is_expected.to create_file('/etc/pki/simp').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/simp/private').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/simp/public').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/simp/private/test.example.domain.pem') }
        it { is_expected.to create_file('/etc/pki/simp/public/test.example.domain.pub') }
        it { is_expected.to create_file('/etc/pki/simp/cacerts').with_ensure('directory') }
      end
    
      context 'with_auditd' do
        let(:params){{ :auditd => true }}

        it { is_expected.to contain_class('auditd') }
        it { is_expected.to create_file('/etc/pki/simp').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/simp/private').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/simp/public').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/simp/private/test.example.domain.pem') }
        it { is_expected.to create_file('/etc/pki/simp/public/test.example.domain.pub') }
        it { is_expected.to create_file('/etc/pki/simp/cacerts').with_ensure('directory') }
      end

    end
  end
end
