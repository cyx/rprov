require File.expand_path("helper", File.dirname(__FILE__))

setup { Redis.connect }

def conf_value(data, key)
 data[/^#{key}\s+(.*)$/, 1]
end

test "path assignment" do
  c = Rprov::Config.generate
  c.path = "/some/path/here/"

  assert c.path == "/some/path/here"
end

test "url" do
  c = Rprov::Config.generate

  assert "redis://:#{c.password}@#{c.host}:#{c.port}" == c.url
end

test "generating" do |r|
  config = Rprov::Config.generate

  assert r.exists("rprov:config:#{config.key}")

  pass, port = r.hmget("rprov:config:#{config.key}", :password, :port)

  assert config.password == pass
  assert config.port == port
end

test "generating with a specified key" do
  config = Rprov::Config.generate("foobar")

  assert config.key == "foobar"
  assert config.password =~ /^[a-zA-Z0-9]{40}$/
  assert config.port.to_i == Rprov::Config::STARTING_PORT
end

test "redis conf" do
  config = Rprov::Config.generate
  config.path = "/data/ferrari"

  assert conf_value(config.redis_conf, :port) == config.port
  assert conf_value(config.redis_conf, :requirepass) == config.password
  assert conf_value(config.redis_conf, :dir) == "/data/ferrari"
  assert conf_value(config.redis_conf, :pidfile) == "/data/ferrari/redis.pid"
  assert conf_value(config.redis_conf, :logfile) == "/data/ferrari/redis.log"
  assert conf_value(config.redis_conf, :bind) == "127.0.0.1"
end

test "safe mode" do
  config = Rprov::Config.generate
  config.path = "/data/ferrari"
  config.paranoid = true

  assert config.redis_conf =~ /^rename-command CONFIG [a-zA-Z0-9]{40}$/
  assert config.redis_conf =~ /^rename-command SLAVEOF ""$/
  assert config.redis_conf =~ /^rename-command BGREWRITEAOF ""$/
  assert config.redis_conf =~ /^rename-command SHUTDOWN [a-zA-Z0-9]{40}$/
  assert config.redis_conf =~ /^rename-command SAVE ""$/
  assert config.redis_conf =~ /^rename-command BGSAVE ""$/
end

test "vm settings behavior" do
  config = Rprov::Config.new("some_key")

  # by default is disabled
  assert config.vm_enabled == "no"

  # setting max memory enables it
  config.memory = "1gb"
  assert config.vm_enabled == "yes"
  assert config.vm_max_memory == "1gb"
end