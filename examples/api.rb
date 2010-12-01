config = Rprov::Config.new("ab1b23b12b3")
config.redis_conf => redis.conf contents

config = Rprov::Config.generate
config.key => "ab1b23b12b3"
config.redis_conf
config.password
config.port
config.redis_url