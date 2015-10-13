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
        it { is_expected.to contain_class('auditd') }
    
        it { is_expected.to create_file('/etc/pki').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/private').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/public').with_ensure('directory') }
        it { is_expected.to create_file('/etc/pki/private/test.example.domain.pem') }
        it { is_expected.to create_file('/etc/pki/public/test.example.domain.pub') }
        it { is_expected.to create_file('/etc/pki/cacerts').with_ensure('directory') }
      end
    end
  end
end
