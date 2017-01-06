require 'spec_helper_acceptance'

test_name 'pki_copy'

describe 'pki_copy' do
  hosts.each do |host|

    context 'with pki = true' do
      let(:pki_true_manifest) { <<-EOM
        pki::copy { 'someapp': }
        pki::copy { 'anotherapp': }
      EOM
      }
      let(:pki_true_hieradata) {{
        'simp_options::pki'         => true,
        'simp_options::pki::source' => '/etc/pki/simp-testing/pki'
      }}
      let(:host_fqdn) { fact_on(host, 'fqdn') }

      it 'should work with no errors' do
        set_hieradata_on(host, pki_true_hieradata)
        apply_manifest_on(host, pki_true_manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, pki_true_manifest, :catch_changes => true)
      end

      # If pki is true or simp, we will manage everything for you!
      it 'should plop the certs in a central place' do
        on host, "test -f /etc/pki/simp_apps/someapp/pki/private/#{host_fqdn}.pem"
        on host, "test -f /etc/pki/simp_apps/someapp/pki/public/#{host_fqdn}.pub"
        on host, "test -f /etc/pki/simp_apps/someapp/pki/cacerts/cacerts.pem"
        on host, "test -f /etc/pki/simp_apps/anotherapp/pki/private/#{host_fqdn}.pem"
        on host, "test -f /etc/pki/simp_apps/anotherapp/pki/public/#{host_fqdn}.pub"
        on host, "test -f /etc/pki/simp_apps/anotherapp/pki/cacerts/cacerts.pem"
      end
    end
    context 'with pki = false, and a destination specified' do
      let(:pki_false_manifest) { <<-EOM
        pki::copy { 'someapp':
          destination => '/etc/pki/alternate_dest'
        }
      EOM
      }
      let(:pki_false_hieradata) {{
        'simp_options::pki'         => false,
        'simp_options::pki::source' => '/etc/pki/simp-testing/pki'
      }}
      let(:host_fqdn) { fact_on(host, 'fqdn') }

      it 'should work with no errors' do
        set_hieradata_on(host, pki_false_hieradata)
        apply_manifest_on(host, pki_false_manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, pki_false_manifest, :catch_changes => true)
      end

      # If pki is false, you need to ensure your alternate directory is created,
      # we won't manage it for you!
      on host, "mkdir -p /etc/pki/alternate_dest"

      it 'should plop the certs in their own special directory' do
        on host, "test -f /etc/pki/alternate_dest/pki/private/#{host_fqdn}.pem"
        on host, "test -f /etc/pki/alternate_dest/pki/public/#{host_fqdn}.pub"
        on host, "test -f /etc/pki/alternate_dest/pki/cacerts/cacerts.pem"
      end
    end
  end
end
