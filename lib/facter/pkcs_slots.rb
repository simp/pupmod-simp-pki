# output from pkcsconf -t
Facter.add('pkcs_slots') do

  def pkcsconf_t
    Facter::Core::Execution.execute('pkcsconf -t')
  end

  setcode do
    require 'yaml'

    begin
      cmd = pkcsconf_t.split("\n")
    rescue Puppet::ExecutionFailure => e
      Puppet.debug "#read_slots had an error -> #{e.inspect}"
      return {}
    end

    # clean the output so the YAML parser will read it
    cmd.each do |line|
      line.gsub!(/\t/,' '*4)        # tabs make YAML unhappy
      line.gsub!(/[^[:print:]]/,'') # removes non-printable characters, like \b
      line.gsub!(/#/,'')            # the hash symbol also makes YAML unhappy
    end
    y = YAML.load(cmd.join("\n"))

    # lowercase all the keys and replace all spaces with _
    properties = []
    y.values.each do |val|
      properties << Hash[val.map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }]
    end

    # isolate the flags
    properties.each do |prop|
      prop['flags_raw'] = prop['flags']
      prop['flags'] = prop['flags_raw'].scan(/([A-Z_]{3,})/ ).flatten
    end

    properties
  end
end