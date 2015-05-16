module Puppet
  newtype(:pki_cert_sync) do
    require 'puppet/util/selinux'
    include Puppet::Util::SELinux

    @doc = <<-EOM
      A puppet type for merging the contents of one directory full of X.509 PKI
      certificates into another while hashing the certificates in a manner
      appropriate for use by most Linux applications (Apache, OpenLDAP, etc...).

      Usage:

      pki_cert_sync { '<target_dir>': source => '<source_dir>' }

      Both directories must exist on the local operating system, remote file
      syncing is not supported. File attributes will all be copied from the
      source directory.

      Any SELinux contexts will be preserved on existing files and copied from
      the source files if the destination file does not exist.
    EOM

    def initialize(args)
      super(args)

      if self[:tag] then
        self[:tag] += ['pki']
      else
        self[:tag] = ['pki']
      end

      if self[:notify] then
        self[:notify] += ["File[#{self[:name]}]"]
      else
        self[:notify] = ["File[#{self[:name]}]"]
      end
    end

    def finish
      # Do stuff here if necessary after the catalog compiles.

      super
    end

    newparam(:name, :namevar => true) do
      desc = <<-EOM
        The target directory into which to place and hash the X.509
        certificates.

        This directory will be left as it was found at the end of the sync just
        in case it is the destination of a recursive file copy with purge
        enabled.
      EOM

      validate do |value|
        Puppet::Util.absolute_path?(value) or
          fail Puppet::Error, "Target directory must be an absolute path, not '#{value}'"
      end
    end

    newparam(:purge, :boolean => true) do
      desc = <<-EOM
        Whether or not to purge the target directory (:name). In general, you
        will want to do this to ensure that systems do not get inappropriate
        CAs added locally.
      EOM

      newvalues(:true,:false)
      defaultto :true
    end

    newproperty(:source) do
      desc = <<-EOM
        The directory into which to copy all materials. All existing materials will be removed.
      EOM

      validate do |value|
        Puppet::Util.absolute_path?(value) or
          fail Puppet::Error, "Source directory must be an absolute path, not '#{value}'"
      end

      def insync?(is)
        # In this case, we want to compare the contents of ourself and
        # self[:name].
        provider.source_insync?(is,resource[:name])
      end

      def change_to_s(currentvalue, newvalue)
        "'#{resource[:source]}' X.509 CA certificates sync'd to '#{resource[:name]}'"
      end
    end

    autorequire(:file) do
      [ self[:name], self[:source] ]
    end

  end
end
