require 'spec_helper'

describe 'pki::copy' do


  let(:facts) {{
    :fqdn => 'test.example.domain:',
    :operatingsystem => 'RedHat',
    :grub_version => '0.9',
    :uid_min => '500'
  }}

  let(:title) {'/test/dir'}

  context 'base' do
    it { should contain_class('pki') }
    it { should create_file('/test/dir/pki').with_ensure('directory') }
    it { should create_file('/test/dir/pki/private').with_ensure('directory') }
    it { should create_file('/test/dir/pki/public').with_ensure('directory') }
    it { should create_file('/test/dir/pki/cacerts').with_ensure('directory') }
  end
end
