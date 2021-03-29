module Trackable
  module Cache
    def self.configure_redis(redis_url: "redis://localhost", redis_password: nil, redis_port: "6379", redis_timeout: 10, redis_namespace: nil)
      redis = Redis.new(
        url: redis_url,
        password: redis_password,
        port: redis_port,
        timeout: redis_timeout,
      )

      @@redis_nsp = Redis::Namespace.new(redis_namespace, redis: redis)
    end

    def self.redis
      if defined?(@@redis_nsp).nil?
        raise "Trackable::Cache.redis is not configure!"
      end

      @@redis_nsp
    end
  end
end
