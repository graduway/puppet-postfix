require 'puppet/confine/postfix_version'

class Puppet::Provider::Postconf < Puppet::Provider
  def self.initvars
    super

    commands postmulti_cmd: 'postmulti'
    commands postconf_cmd: 'postconf'
  end

  attr_accessor :config_dir

  # Always make the resource methods.
  def self.resource_type=(resource)
    super
    mk_resource_methods
  end

  def self.prefetch(resources)
    provs = instances
    resources.keys.each do |name|
      if (provider = provs.find { |p| p.name == name })
        resources[name].provider = provider
      end
    end
  end

  def initialize(*args)
    super(*args)

    @property_flush = {}
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def flush
    write_entry

    @property_hash.clear
  end

  def self.postfix_instances
    postmulti_cmd('-l').split("\n").each_with_object({}) do |line, i|
      line = line.split(%r{ +}, 4)
      i[line[0]] = line[3]
      i
    end
  end

  protected

  def write_entry
    if @property_flush[:ensure] == :absent
      postconf('-X', entry_key)
      return
    end

    postconf("#{entry_key}=#{entry_value}")
  end

  def entry_key
    resource[:name].rpartition('::')[2]
  end

  def entry_value
    raise Puppet::DevError, "Provider #{name} has not defined the 'entry_value' class method"
  end

  def postconf(*args)
    if (conf = config_dir)
      postconf_cmd('-c', conf, *args)
    else
      postconf_cmd(*args)
    end
  end

  def config_dir
    instance = resource.instance_name
    if instance.nil?
      nil
    else
      @config_dir ||= self.class.postfix_instances[instance]
    end
  end
end
