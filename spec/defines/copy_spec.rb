require 'spec_helper'

describe 'pki::copy' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts){ facts }

      context "on #{os}" do
        let(:title) {'/test/dir'}
        let(:params) {{ :source => "/foo/bar", :pki => true }}

        context 'with non-default source' do
          it { is_expected.to_not contain_class('pki') }
          it { is_expected.to create_file('/test/dir/pki').with({
            :ensure => 'directory'})
          }
          it { is_expected.to create_file('/test/dir/pki/private').with({
            :source => "/foo/bar/private",
            :ensure => "directory"})
          }
          it { is_expected.to create_file('/test/dir/pki/public').with({
            :source => "/foo/bar/public",
            :ensure => "directory"})
          }
          it { is_expected.to create_file('/test/dir/pki/cacerts').with({
            :source => "/foo/bar/cacerts",
            :ensure => "directory"})
          }
        end
        context 'with pki=false' do
          let(:params) {{ :pki => false }}
          it { is_expected.to_not contain_class('pki') }
        end
        context 'with pki=simp' do
          let(:params) {{ :pki => 'simp' }}
          it { is_expected.to contain_class('pki') }
        end
      end
    end
  end
end
