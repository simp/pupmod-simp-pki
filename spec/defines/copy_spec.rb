require 'spec_helper'

shared_examples_for 'pki true' do
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_file('/etc/pki/simp_apps').with_purge(true) }
  it { is_expected.to create_file('/etc/pki/simp_apps/foo')}
  it { is_expected.to create_file('/etc/pki/simp_apps/foo/x509')}
  it { is_expected.to create_file('/etc/pki/simp_apps/foo/x509/public').with(:source => '/etc/pki/simp/x509/public')}
  it { is_expected.to create_file('/etc/pki/simp_apps/foo/x509/private').with(:source => '/etc/pki/simp/x509/private')}
  it { is_expected.to create_file('/etc/pki/simp_apps/foo/x509/cacerts').with(:source => '/etc/pki/simp/x509/cacerts')}
  it { is_expected.to_not create_file('/etc/pki/simp_apps/foo/pki') }
end

describe 'pki::copy' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts){ facts }
      context "on #{os}" do

        let(:title) {'foo'}

        context 'with pki => false and specified destination' do
          let(:params) {{:pki => false, :destination => '/bar/baz' }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to_not create_notify('pki_copy_foo') }
          it { is_expected.to create_file('/etc/pki/simp_apps').with_purge(true) }
          it { is_expected.to_not contain_class('pki') }
          it { is_expected.to create_file('/bar/baz/pki')}
          it { is_expected.to create_file('/bar/baz/pki/public').with(:source => '/etc/pki/simp/x509/public')}
          it { is_expected.to create_file('/bar/baz/pki/private').with(:source => '/etc/pki/simp/x509/private')}
          it { is_expected.to create_file('/bar/baz/pki/cacerts').with(:source => '/etc/pki/simp/x509/cacerts')}
        end

        context 'with pki => false and specified destination and alternate source' do
          let(:params) {{:pki => false, :destination => '/bar/baz', :source => '/some/certs'}}
          it { is_expected.to compile.with_all_deps}
          it { is_expected.to create_file('/bar/baz/pki/public').with(:source => '/some/certs/public')}
          it { is_expected.to create_file('/bar/baz/pki/private').with(:source => '/some/certs/private')}
          it { is_expected.to create_file('/bar/baz/pki/cacerts').with(:source => '/some/certs/cacerts')}
        end

        context 'with pki => false and no specified destination' do
          let(:params) {{:pki => false}}
          it do
            expect {
              is_expected.to compile
            }.to raise_error(/You must specify a \$destination/)
          end
        end

        context 'with pki => true and no specified destination' do
          let(:params) {{:pki => true }}
          it { is_expected.to_not contain_class('pki') }
          it_should_behave_like "pki true"
        end

        context 'with pki => true and specified destination' do
          let(:params) {{:pki => true, :destination => '/bar/baz'}}
          it { is_expected.to create_notify('pki_copy_foo') }
          it { is_expected.to_not contain_class('pki') }
          it_should_behave_like "pki true"
        end

        context 'with pki => simp' do
          let(:params) {{:pki => 'simp'}}
          it { is_expected.to contain_class('pki')}
          it_should_behave_like "pki true"
        end
      end
    end
  end
end
