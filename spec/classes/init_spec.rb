require 'spec_helper'

describe 'pki' do

  let(:facts) {{
    :fqdn => 'test.example.domain',
    :operatingsystem => 'RedHat',
    :grub_version => '0.9',
    :uid_min => '500'
  }}

  it { should create_class('pki') }

  context 'base' do
    it { should compile.with_all_deps }
    it { should contain_class('auditd') }

    it { should create_file('/etc/pki').with_ensure('directory') }
    it { should create_file('/etc/pki/private').with_ensure('directory') }
    it { should create_file('/etc/pki/public').with_ensure('directory') }
    it { should create_file('/etc/pki/private/test.example.domain.pem') }
    it { should create_file('/etc/pki/public/test.example.domain.pub') }
    it { should create_file('/etc/pki/public/test.example.domain_rsa.pem') }
    it { should create_file('/etc/pki/cacerts').with_ensure('directory') }
  end
end
