require 'spec_helper_acceptance'

test_name 'pki::purge_key_dirs'

describe 'pki::purge_key_dirs' do
  let(:manifest) do
    <<~EOM
      include pki
      pki::copy { 'someapp': }
      Class['pki'] -> Pki::Copy['someapp']
    EOM
  end

  let(:base) { '/etc/pki/simp/x509' }
  let(:app_dir) { '/etc/pki/simp_apps/someapp/x509' }
  let(:purge_hieradata) { hieradata.merge('pki::purge_key_dirs' => true) }

  # The keydist directory the pki class serves keys from. `let` values are not
  # available in context hooks, so this is a method.
  def keydist_dir(host, keydist_module)
    "#{puppet_modulepath_on(host).first}/#{keydist_module}/files/keydist"
  end

  # simp_options::pki => the module the pki class reads keys from
  { true => 'pki', 'simp' => 'pki_files' }.each do |pki, keydist_module|
    hosts.each do |host|
      context "on #{host} with simp_options::pki => #{pki}" do
        let(:hieradata) { { 'simp_options::pki' => pki } }
        let(:host_fqdn) { fact_on(host, 'networking.fqdn') }

        before(:context) do
          run_fake_pki_ca_on(host, host) unless host.file_exist?('/root/pki/keydist')
          copy_keydist_to(host, keydist_dir(host, keydist_module))
        end

        it 'applies with purging off' do
          set_hieradata_on(host, hieradata)
          apply_manifest_on(host, manifest, catch_failures: true)
        end

        it 'keeps keys it does not manage when purging is off' do
          on(host, "touch #{base}/private/old.example.domain.pem #{base}/public/old.example.domain.pub")
          apply_manifest_on(host, manifest, catch_failures: true)

          on(host, "test -f #{base}/private/old.example.domain.pem")
          on(host, "test -f #{base}/public/old.example.domain.pub")
          on(host, "test -f #{app_dir}/private/old.example.domain.pem")
          on(host, "test -f #{app_dir}/public/old.example.domain.pub")
        end

        it 'removes the stale keys from the key directories and the copies when purging is on' do
          set_hieradata_on(host, purge_hieradata)
          apply_manifest_on(host, manifest, catch_failures: true)

          on(host, "test ! -e #{base}/private/old.example.domain.pem")
          on(host, "test ! -e #{base}/public/old.example.domain.pub")
          on(host, "test ! -e #{app_dir}/private/old.example.domain.pem")
          on(host, "test ! -e #{app_dir}/public/old.example.domain.pub")
        end

        it "keeps the host's own key pair when purging is on" do
          on(host, "test -f #{base}/private/#{host_fqdn}.pem")
          on(host, "test -f #{base}/public/#{host_fqdn}.pub")
          on(host, "test -f #{app_dir}/private/#{host_fqdn}.pem")
          on(host, "test -f #{app_dir}/public/#{host_fqdn}.pub")
        end

        it 'is idempotent with purging on' do
          apply_manifest_on(host, manifest, catch_changes: true)
        end

        it 'leaves files alone once purging is turned off again' do
          set_hieradata_on(host, hieradata)
          on(host, "touch #{base}/private/by_hand.pem")
          apply_manifest_on(host, manifest, catch_failures: true)

          on(host, "test -f #{base}/private/by_hand.pem")
        end

        context "when the host's keys are missing from the server" do
          def host_keydist(host, keydist_module)
            "#{keydist_dir(host, keydist_module)}/#{fact_on(host, 'networking.fqdn')}"
          end

          before(:context) { on(host, "mv #{host_keydist(host, keydist_module)} /root/host_keydist.bak") }

          after(:context) { on(host, "mv /root/host_keydist.bak #{host_keydist(host, keydist_module)}") }

          it 'warns and does not purge' do
            set_hieradata_on(host, purge_hieradata)
            result = apply_manifest_on(host, manifest, expect_failures: true)

            expect(result.stderr + result.stdout).to match(%r{pki: not purging #{base}/private})
            on(host, "test -f #{base}/private/by_hand.pem")
            on(host, "test -f #{base}/private/#{host_fqdn}.pem")
            on(host, "test -f #{base}/public/#{host_fqdn}.pub")
          end
        end

        # RSpec runs a group's own examples before its nested groups, so this
        # needs its own context to run after the one above
        context 'when the keys are back on the server' do
          it 'purges again' do
            set_hieradata_on(host, purge_hieradata)
            apply_manifest_on(host, manifest, catch_failures: true)

            on(host, "test ! -e #{base}/private/by_hand.pem")
            on(host, "test -f #{base}/private/#{host_fqdn}.pem")
          end
        end
      end
    end
  end
end
