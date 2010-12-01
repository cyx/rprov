require "redis"
require "nest"
require "digest/sha1"
require "erb"
require "fileutils"

class Rprov
  Conflict = Class.new(StandardError)

  VERSION = "0.0.1"

  autoload :Config,    "rprov/config"
  autoload :Decorator, "rprov/decorator"

  attr_accessor :memory, :host, :paranoid

  def start(path)
    `redis-server #{redis_conf(path)}`
  end

  def stop(path)
    conf  = Rprov::Config.new(key(path))
    redis = Redis.connect(:port => conf.port, :password => conf.password)
    redis.client.process(conf.shutdown_cmd)
  end

  def setup(path)
    raise Conflict if redis_conf(path)

    FileUtils.mkdir_p(path) if not File.exist?(path)

    conf = Config.generate
    conf.path     = path
    conf.memory   = memory if memory
    conf.host     = host if host
    conf.paranoid = paranoid if paranoid

    where = File.expand_path(File.join(path, "redis.%s.conf" % conf.key))

    File.open(where, "w") do |file|
      file.write conf.redis_conf
    end
  end

  def info(path)
    key = key(path)
    c = Config.new(key)

    puts "\nREDIS_URL:\n    redis://:#{c.password}@#{c.host}:#{c.port}"
    puts "\nRun `rprov start #{path}` to start this instance"
  end

private
  def key(path)
    redis_conf(path)[/redis\.(.*?)\.conf/, 1]
  end

  def redis_conf(path)
    Dir[File.expand_path(File.join(path, "redis.*.conf"))].first
  end
end