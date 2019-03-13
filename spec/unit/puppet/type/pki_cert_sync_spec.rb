#!/usr/bin/env rspec

require 'spec_helper'

pki_cert_sync_type = Puppet::Type.type(:pki_cert_sync)

describe "#{pki_cert_sync_type}" do

  context 'constructor' do
    it 'should accept a valid required parameters and set defaults' do
      resource = pki_cert_sync_type.new( {
        :name   => '/etc/pki/simp_apps/app1/x509/cacerts',
        :source => '/etc/pki/simp/x509/cacerts'
      } )
      expect(resource[:name]).to eq('/etc/pki/simp_apps/app1/x509/cacerts')
      expect(resource[:source]).to eq('/etc/pki/simp/x509/cacerts')
      expect(resource.generate_pem_hash_links?).to eq(true)
      expect(resource.purge?).to eq(true)
      expect(resource[:tag]).to eq(['pki'])
    end

    it 'should set optional parameters' do
      resource = pki_cert_sync_type.new( {
        :name                    => '/etc/pki/simp_apps/app1/x509/cacerts',
        :source                  => '/etc/pki/simp/x509/cacerts',
        :generate_pem_hash_links => false,
        :purge                   => false
      } )
      expect(resource[:name]).to eq('/etc/pki/simp_apps/app1/x509/cacerts')
      expect(resource[:source]).to eq('/etc/pki/simp/x509/cacerts')
      expect(resource.generate_pem_hash_links?).to be_falsey
      expect(resource.purge?).to be_falsey
      expect(resource[:tag]).to eq(['pki'])
    end

    it 'should fail if name is not an absolute path' do
      expect {
        pki_cert_sync_type.new( {
        :name   => 'cacerts',
        :source => '/etc/pki/simp/x509/cacerts'
      } )
      }.to raise_error(/Target directory must be an absolute path/)
    end

    it 'should fail if source is not an absolute path' do
      expect {
        pki_cert_sync_type.new( {
        :name   => '/etc/pki/simp_apps/app1/x509/cacerts',
        :source => 'cacerts'
      } )
      }.to raise_error(/Source directory must be an absolute path/)
    end
  end

  context '#change_to_s' do
    it 'should print an intelligible change message' do
      resource = pki_cert_sync_type.new( {
        :name   => '/target',
        :source => '/source'
      } )
      expected_msg = "'/source' X.509 CA certificates sync'd to '/target'"
      actual_msg = resource.property(:source).change_to_s('unused', 'unused')
      expect(actual_msg).to eq(expected_msg)
    end
  end
end

