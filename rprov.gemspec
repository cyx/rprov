Gem::Specification.new do |s|
  s.name = 'rprov'
  s.version = "0.0.1"
  s.summary = %{Redis Provisioning}
  s.description = %{Rprov is a simple command line utility which helps
                    you provision and manage Redis instances easily.}
  s.date = "2010-12-02"
  s.authors = ["Cyril David", "Michel Martens", "Damian Janowski"]
  s.email = ["cyx@pipetodevnull.com", "michel@soveran.com", "djanowski@dimaion.com"]
  s.homepage = "http://github.com/cyx/rprov"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.files = ["lib/rprov/config.rb", "lib/rprov/decorator.rb", "lib/rprov.rb", "README", "LICENSE", "test/config_test.rb", "test/helper.rb", "test/rprov_test.rb", "templates/redis.conf.erb"]

  s.require_paths = ['lib']

  s.add_dependency "redis"
  s.add_dependency "nest"
  s.add_development_dependency "cutest"
  s.has_rdoc = false
  s.executables.push "rprov"
end
