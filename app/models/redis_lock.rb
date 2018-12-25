class RedisLock
  extend ActiveSupport::Concern

  def self.get_instance
    redis = Redis.new(url: Rails.application.secrets.redis_url, password: Rails.application.secrets.redis_password)

    self.nsp = Redis::Namespace.new(Rails.application.secrets.redis_namespace, redis: redis)
  end

  def self.lock(key, lock: true, expire: 10)
    redis = self.get_instance

    wait_duration = 0.01
    expire_in = DateTime.now + expire.seconds

    if lock
      while redis.setnx(key, expire_in) == false
        time = redis.get(key)

        if time
          time = DateTime.parse(time)

          if DateTime.now >= time
            Rails.logger.error "ALERT REDIS LOCK #{key}"
            redis.del(key)
          end
        end

        sleep wait_duration
      end
    else
      if redis.setnx(key, expire_in)
        return true
      else
        return false
      end
    end
  end

  def self.unlock(key)
    redis = self.get_instance

    redis.del(key)
  end
end
