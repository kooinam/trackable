class RedisLock
  extend ActiveSupport::Concern

  def self.get_instance
    redis = Redis.new(url: Rails.application.secrets.redis_url, password: Rails.application.secrets.redis_password)

    nsp = Redis::Namespace.new(Rails.application.secrets.redis_namespace, redis: redis)

    nsp
  end

  def self.lock(key, lock: true, expire: 10)
    start_at = DateTime.now
    redis = self.get_instance

    wait_duration = 0.01
    expire_in = DateTime.now + expire.seconds

    if lock
      while redis.setnx(key, expire_in) == false
        value = redis.get(key)

        if value
          time = nil

          begin
            time = DateTime.parse(value)
          rescue Exception => e
            time = DateTime.now

            DevMessage.track("Redis LOCK Error #{value} #{key} #{e}", 'REDIS LOCK ERROR', important: true)
          end

          if DateTime.now >= time
            DevMessage.track("Redis LOCK LOCKED #{key} #{start_at} #{time}", 'REDIS', important: true)

            Rails.logger.error "ALERT REDIS LOCK #{key}"
            redis.del(key)
          end
        end

        sleep wait_duration
      end

      true
    else
      if redis.setnx(key, expire_in)
        return true
      else
        value = redis.get(key)

        if value
          time = nil

          begin
            time = DateTime.parse(value)
          rescue Exception => e
            time = DateTime.now

            DevMessage.track("Redis LOCK Error #{value} #{key} #{e}", 'REDIS LOCK ERROR', important: true)
          end

          if DateTime.now >= time
            DevMessage.track("Redis LOCK LOCKED #{key} #{start_at} #{time}", 'REDIS', important: true)

            Rails.logger.error "ALERT REDIS LOCK #{key}"
            redis.del(key)

            redis.setnx(key, expire_in)

            return true
          else
            return false
          end
        end
      end
    end
  end

  def self.unlock(key)
    redis = self.get_instance

    redis.del(key)
  end
end
