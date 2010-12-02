class Rprov
  class Decorator
    attr :component

    def initialize(component)
      @component = component
    end

    def start(path)
      init("Starting Redis Instance: `#{path}`")

      begin
        component.start(path)
      rescue Rprov::Missing
        fail_missing(path)
      end
    end

    def stop(path)
      init("Stopping Redis Instance: `#{path}`")

      begin
        component.stop(path)
      rescue Errno::ECONNREFUSED
        fail("The instance appears to be down.")
      rescue Rprov::Missing
        fail_missing(path)
      else
        say("Done!")
      end
    end

    def setup(path)
      init("Setting up Redis Instance: #{path}")

      begin
        component.setup(path)
      rescue Rprov::Conflict
        fail("The path #{path} already exists.")
      else
        say("Done!")
      end
    end

    def info(path)
      begin
        component.info(path)
      rescue Rprov::Missing
        fail_missing(path)
      end
    end

  private
    def init(str)
      puts "-----> #{str}"
    end

    def fail(str)
      puts "!!     #{str}"
    end

    def fail_missing(path)
      fail("Tried to run rprov on non-existent path `#{path}`.")
      fail("Maybe try `rprov setup #{path}` first?")
    end

    def say(str)
      puts "       #{str}"
    end
  end
end