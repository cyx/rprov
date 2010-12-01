require "cutest"
require "stringio"

$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))

require "rprov"

def TMP(*args)
  File.join(File.dirname(__FILE__), "tmp", *args)
end

TMP = TMP()

prepare do
  FileUtils.rm_rf(TMP) if File.exist?(TMP)
  FileUtils.mkdir_p(TMP)

  redis = Redis.connect
  redis.flushdb
end

module Cleanup
  def test(*args, &block)
    begin
      super
    rescue Exception => e
      pids = `ps aux`.
        split("\n").
        grep(/redis-server \//).
        map { |e| e.split(/\s+/)[1] }.
        flatten

      pids.each { |pid| Process.kill("TERM", pid.to_i) }

      raise e
    ensure
      FileUtils.rm_rf(TMP)
    end
  end
end

include Cleanup

class Cutest::Scope
  include Cleanup
end

def silenced
  stdout, $stdout = $stdout, StringIO.new

  yield
ensure
  $stdout = stdout
end