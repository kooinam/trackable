class RedisLock
  extend ActiveSupport::Concern

  def self.get_instance
    broadcast_profile = Rails.application.sidekiq_profile

    redis = Redis.new(
      url: broadcast_profile.url, 
      password: broadcast_profile.password, 
      port: broadcast_profile.port,
      timeout: broadcast_profile.timeout
    )

    nsp = Redis::Namespace.new(broadcast_profile.namespace, redis: redis)

    nsp
  end

  def self.lock(key, lock: true, expire: 10)
    res = false
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

      res = true
    else
      if redis.setnx(key, expire_in)
        res = true
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
            redis.del(key)

            redis.setnx(key, expire_in)

            res = true
          else
            res = false
          end
        end
      end
    end

    redis.redis.close

    res
  end

  def self.unlock(key)
    redis = self.get_instance

    redis.del(key)

    redis.redis.close
  end
end
