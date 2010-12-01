class Rprov
  class Decorator
    attr :component

    def initialize(component)
      @component = component
    end

    def start(path)
      init("Starting Redis Instance: #{path}")

      component.start(path)

      if $?.success?
        say("Done!")
      else
        if not File.exist?(path)
          fail("#{path} doesn't exist. Try `rprov setup #{path}` first.")
        else
          fail("Unable to start. There might be a problem with the config.")
        end
      end
    end

    def stop(path)
      init("Stopping Redis Instance: #{path}")

      begin
        component.stop(path)
      rescue Errno::ECONNREFUSED
        fail("The instance appears to be down.")
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

  private
    def init(str)
      puts "-----> #{str}"
    end

    def fail(str)
      puts "!!     #{str}"
    end

    def say(str)
      puts "       #{str}"
    end
  end
end