Puppet::Type.type(:pki_cert_sync).provide(:redhat) do

  def initialize(args)
    super(args)
  end

  def source
    src = resource[:source]
    File.directory?(src) or fail Puppet::Error, "'#{src}' is not a valid directory."

    hash_targets = {}
    @to_link = {}
    @directories = []
    @concatted_certs = ''

    Dir.chdir(src) do
      # Get all the files, but not the symlinks or cacerts.pem.
      to_parse = Dir.glob('**/*').sort
      to_parse.delete_if{|x| File.symlink?(x)}
      to_parse.delete_if{|x| x == 'cacerts.pem' }

      # Get all of the directories for later use.
      @directories = to_parse.select { |x| File.directory?(x) }
      # Remove directories from to_parse, they don't belong in to_link!
      to_parse.delete_if{|x| File.directory?(x) }

      # Determine what they all hash to.
      to_parse.each do |file|
        begin
          cert = OpenSSL::X509::Certificate.new(File.read(file))
        rescue OpenSSL::X509::CertificateError
          # We had a problem, skip this file.
          Puppet.warning("File '#{file}' does not look like an X.509 certificate, skipping")
          next
        end

        @concatted_certs += IO.read(file)

        cert_hash = sprintf("%08x",cert.subject.hash)
        hash_targets[cert_hash] ||= Array.new

        file_prefix,file_suffix = file.split('.')
        if file_prefix == cert_hash then
          hash_targets[cert_hash].insert(file_suffix.to_i,file)
        else
          i = 0
          while not hash_targets[cert_hash][i].nil? do i += 1 end
          hash_targets[cert_hash][i] = file
        end
      end
    end

    hash_targets.each_key do |cert_hash|
      i = 0
      hash_targets[cert_hash].each do |file|
        next if file == 'cacerts.pem'
        @to_link[file] = "#{cert_hash}.#{i}"
        i += 1
      end
    end

    @to_link['cacerts.pem'] = 'cacerts.pem'
    @to_link
  end

  def source_insync?(src,target)
    # At this point src is a hash with the following format:
    #   PEM_file -> link
    #   PEM_file2 -> link2
    #   ...
    #
    File.directory?(target) or Dir.mkdir(target, 755)

    insync = true
    Dir.chdir(target) do

      # If we're purging, and the number of files is different, then we're
      # not in sync.
      files = Dir.glob('**/*').select { |f| File.file?(f) }
      if files.count != src.to_a.flatten.uniq.count and resource[:purge] == :true then
        Puppet.debug("Different number of files from #{resource[:source]} to #{resource[:name]}")
        insync = false
      end

      # If we're purging, and the number of directories is different, then we're
      # not in sync.
      if resource[:purge] == :true then
        dirs = Dir.glob('**/*').select { |d| File.directory?(d) }
        if not dirs.uniq.sort == @directories.uniq.sort then
          Puppet.debug("Different number of directories from #{resource[:source]} to #{resource[:name]}")
          insync = false
        end
      end

      # If files the same length, but we have a file name that is
      # different, then we're not in sync.
      src.each_key do |k|
        if not files.include?(k) then
          Puppet.debug("Different filenames from #{resource[:source]} to #{resource[:name]}")
          insync = false
          break
        end
      end

      # If all files have the same name, then we need to compare each one.
      src.each_key do |file|
        next if file == 'cacerts.pem'
        # If we've gotten here, we need to exclude any target that doesn't
        # exist for the purge settings.
        if File.file?(file) and file_diff(file,"#{resource[:source]}/#{file}") then
          Puppet.debug("File contents differ between #{resource[:source]} and #{resource[:name]}")
          insync = false
          break
        end
      end
    end

    insync
  end

  def source=(should)
    # If the PEM file has the same name as the link, do not create a new link,
    # just copy the file.

    Dir.chdir(resource[:name]) do

      # Purge ALL THE THINGS
      if resource[:purge] == :true then
        # Make sure not to delete directories or certs (and symlinks) that we might currently be using.
        (Dir.glob('**/*') - [@to_link.to_a].flatten - @directories.flatten).each do |to_purge|
          if not ([@to_link.to_a].flatten).any? { |s| s.include?(to_purge) } then
            Puppet.notice("Purging '#{resource[:name]}/#{to_purge}'")
            # Ensure the file still exists.  If a file's subdirectory was purged first
            # it won't be there.
            FileUtils.rm_rf(to_purge) if File.exists?(to_purge)
          end
        end
      end

      # This is simply a canary file to get File['/etc/pki/cacerts'] to trigger
      # a change for all those lovely legacy files out there. Should be
      # deprecated at some point since it's basically noise.
      FileUtils.touch('.sync_updated')
      FileUtils.chmod(0000, '.sync_updated')
      # End garbage hacky code

      if !File.exists?("#{resource[:name]}/cacerts.pem")
        File.open("#{resource[:name]}/cacerts.pem", 'w') {|f| f.write(@concatted_certs)}
        File.chmod(0644, "#{resource[:name]}/cacerts.pem")
      else
        !(IO.read("#{resource[:name]}/cacerts.pem").eql? @concatted_certs) and
          File.open("#{resource[:name]}/cacerts.pem", 'w') {|f| f.write(@concatted_certs)}
      end

      # Take care of directories first; make them if they don't already exist.
      @directories.each do |dir|
        FileUtils.mkdir_p(dir)
      end

      # Now copy over those items that differ and link them.
      @to_link.each_pair do |src,link|
        if File.exist?(src) then
          selinux_context = resource.get_selinux_current_context("#{resource[:name]}/#{src}")
        else
          selinux_context = resource.get_selinux_current_context("#{resource[:source]}/#{src}")
        end

        selinux_context.nil? and
          Puppet.debug("Could not get selinux context for '#{resource[:source]}/#{src}'")

        unless src == 'cacerts.pem' then
          FileUtils.cp("#{resource[:source]}/#{src}",src,{:preserve => true})
          resource.set_selinux_context("#{resource[:name]}/#{src}",selinux_context).nil? and
            Puppet.debug("Could not set selinux context on '#{src}'")
        end

        # Only link if the names are different.
        if src != link then
          FileUtils.ln_sf(src,link)
          # Have to set the SELinux context here too since symlinks can have
          # different contexts than files.
          resource.set_selinux_context("#{resource[:name]}/#{link}",selinux_context).nil? and
            Puppet.debug("Could not set selinux context on link '#{link}'")
        end
      end
    end
  end

  # Helper Methods

  # Ok, this is definitely not DRY since this is in concat_build. However, I
  # haven't found a consistent way of having a common library of junk for
  # custom types to use. Perhaps I should start collecting these into a simp
  # package.

  # Does a comparison of two files and returns true if they differ and false if
  # they do not.
  def file_diff(src, dest)
    if not File.exist?(src) then
      fail Puppet::Error,"Could not diff non-existant source file #{src}."
    end

    # If the destination isn't there, it's different.
    return true unless File.exist?(dest)

    # If the sizes are different, it's different.
    return true if File.stat(src).size != File.stat(dest).size

    # If we've gotten here, brute force by 512B at a time. Stop when a chunk differs.
    s_file = File.open(src,'r')
    d_file = File.open(dest,'r')

    retval = false
    while not s_file.eof? do
      if s_file.read(512) != d_file.read(512) then
        retval = true
        break
      end
    end

    s_file.close
    d_file.close
    return retval
  end
end
