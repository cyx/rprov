class Rprov
  class Config
    STARTING_PORT = 10_000

    DEFAULTS = {
      :appendfsync   => "everysec",
      :host          => "127.0.0.1",
      :vm_enabled    => "no",
      :vm_max_memory => 0,
      :paranoid      => false
    }

    attr :key
    attr :password
    attr :port
    attr :paranoid

    attr_accessor :host
    attr_accessor :path
    attr_accessor :appendfsync
    attr_accessor :vm_enabled
    attr_accessor :vm_max_memory

    def initialize(key)
      @key = key

      @password, @port = redis.hmget(:password, :port)

      DEFAULTS.each do |key, value|
        instance_variable_set(:"@#{key}", redis.hget(key) || value)
      end
    rescue Errno::ECONNREFUSED
      raise Errno::ECONNREFUSED, "You need to setup a master redis server."
    end

    def memory=(memory)
      self.vm_max_memory = memory
      self.vm_enabled = "yes"
    end

    def paranoid=(val)
      @paranoid = val

      if val
        redis.hmset(:config_cmd,   self.class.random_string,
                    :shutdown_cmd, self.class.random_string)
      end
    end

    def config_cmd()   redis.hget(:config_cmd) || :config end
    def shutdown_cmd() redis.hget(:shutdown_cmd) || :shutdown end

    def redis_conf
      redis_conf_erb.result(binding)
    end

    def self.generate(key = gen_key)
      redis[key].hmset(:port, gen_port, :password, random_string)

      return new(key)
    end

    def self.random_string
      Digest::SHA1.hexdigest(uuid + Time.now.to_f.to_s)
    end

    def self.redis
      Nest.new(:rprov)[:config]
    end

  private
    def redis_conf_erb
      ERB.new(File.read(template_path), nil, "-")
    end

    def template_path
      File.expand_path("../../templates/redis.conf.erb",
                       File.dirname(__FILE__))
    end

    def redis
      self.class.redis[key]
    end

    def self.gen_port
      unless redis[:port].setnx(STARTING_PORT)
        redis[:port].incr
      end

      redis[:port].get
    end

    def self.gen_key
      Digest::SHA1.hexdigest(uuid)
    end

    def self.uuid
      `uuidgen`.strip
    end
  end
end