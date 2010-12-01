require File.expand_path("helper", File.dirname(__FILE__))

setup do
  [Redis.connect, Rprov.new]
end

def redis_conf(path = "redis.*.conf")
  Dir[TMP(path)].first
end

def redis_conf_data
  File.read(redis_conf)
end

def redis_conf_id(conf = redis_conf)
  conf[/redis\.(.*?)\.conf/, 1]
end

def port_pass(redis)
  redis.hmget("rprov:config:#{redis_conf_id}", :port, :password)
end

test "basic setup" do |redis, rprov|
  silenced do
    rprov.setup(TMP)
  end

  assert redis_conf
  assert redis.exists("rprov:config:#{redis_conf_id}")
end

test "setup on a non existing directory" do |redis, rprov|
  silenced do
    rprov.setup(TMP("subdir"))
  end

  conf = redis_conf("subdir/redis.*.conf")

  assert conf
  assert redis.exists("rprov:config:#{redis_conf_id(conf)}")
end

test "setup with memory specification" do |redis, rprov|
  silenced do
    rprov.memory = "1gb"
    rprov.setup(TMP)
  end

  assert redis_conf_data =~ /^vm-enabled yes$/
  assert redis_conf_data =~ /^vm-max-memory 1gb$/
end

test "setup with host specification" do |redis, rprov|
  silenced do
    rprov.host = "test.server.com"
    rprov.setup(TMP)
  end

  assert redis_conf_data =~ /^bind test.server.com$/
end

test "setting up on an already setup path" do |redis, rprov|
  rprov.setup(TMP)

  caught = true

  path = catch :already_exists do
    rprov.setup(TMP)
    caught = false
  end

  assert caught
  assert path == TMP

  configs =
    redis.keys("rprov:config:*").reject { |k|
      k == "rprov:config:port"
    }.size

  assert configs == 1
end

# starting
scope do
  setup do
    [Redis.connect, Rprov.new]
  end

  test "will setup when not existing" do |redis, rprov|
    silenced do
      rprov.setup(TMP)
      rprov.start(TMP)
    end

    port, pass = port_pass(redis)

    r = Redis.connect(:port => port, :password => pass)

    assert r.set("foo", "bar")
    assert r.get("foo") == "bar"

    r.client.process(:shutdown)
  end

  test "running existing config" do |redis, rprov|
    silenced do
      rprov.setup(TMP)
      rprov.start(TMP)
    end

    port, pass = port_pass(redis)

    r = Redis.connect(:port => port, :password => pass)

    assert r.set("foo", "bar")
    assert r.get("foo") == "bar"

    r.client.process(:shutdown)
  end
end

# stopping
scope do
  setup do
    [Redis.connect, Rprov.new]
  end

  test "start / stop" do |redis, rprov|
    silenced do
      rprov.setup(TMP)
      rprov.start(TMP)
    end

    port, pass = port_pass(redis)

    r = Redis.connect(:port => port, :password => pass)

    r.set("foo", "bar")

    rprov.stop(TMP)

    foo =
      begin
        r.client.get("foo")
      rescue
      end

    assert foo != "bar"
  end

  test "start / stop / start" do |redis, rprov|
    silenced do
      rprov.setup(TMP)
      rprov.start(TMP)
    end

    port, pass = port_pass(redis)

    r = Redis.connect(:port => port, :password => pass)

    r.set("foo", "bar")

    rprov.stop(TMP)

    silenced do
      rprov.start(TMP)
    end

    sleep 0.2

    r = Redis.connect(:port => port, :password => pass)
    assert r.get("foo") == "bar"

    rprov.stop(TMP)
  end
end