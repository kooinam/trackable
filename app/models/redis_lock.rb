class RedisLock
  extend ActiveSupport::Concern

  attr_accessor(
    :key,
    :expire,
    :timeout,
  )

  def self.setup_profile_config(config = {})
    @@profile_config = config
  end

  def self.profile_config
    @@profile_config
  end

  def self.get_instance
    redis = Redis.new(
      url: profile_config[:url],
      password: profile_config[:password],
      port: profile_config[:port],
      timeout: profile_config[:timeout],
    )

    nsp = Redis::Namespace.new(profile_config[:namespace], redis: redis)

    nsp
  end

  def self.lock(key, lock: true, expire: 10, timeout: nil)
    redis_lock = RedisLock.new(key, expire: expire, timeout: timeout)
    response = false

    if lock
      response = redis_lock.pending_lock()
    else
      response = redis_lock.direct_lock()
    end

    redis_lock.close()

    response
  end

  def self.unlock(key)
    RedisLock.new(key).unlock
  end

  def initialize(key, expire: nil, timeout: nil)
    self.key = key
    self.expire = expire
    self.timeout = timeout
  end

  def pending_lock
    response = false

    redis = self.class.get_instance
    key = self.key
    expire = self.expire

    start_at = DateTime.now
    expire_in = DateTime.now + expire.seconds

    wait_duration = 0.01
    total_wait_duration = 0

    # if the key is exist, keep waiting until it release
    while redis.set(key, expire_in, nx: true, ex: expire) == false
      total_wait_duration += wait_duration

      check_timeout(total_wait_duration, start_at)

      sleep wait_duration
    end

    response = true

    response
  end

  def direct_lock
    response = false

    key = self.key
    expire = self.expire

    redis = self.class.get_instance

    expire_in = DateTime.now + expire.seconds

    if redis.set(key, expire_in, nx: true, ex: expire)
      response = true
    else
      response = false
    end

    response
  end

  def unlock
    redis = self.class.get_instance

    redis.del(self.key)

    redis.redis.close
  end

  def close
    redis = self.class.get_instance

    redis.redis.close
  end

  private

  def check_timeout(total_wait_duration, start_at)
    timeout = self.timeout
    key = self.key

    if timeout.nil?
      return
    end

    if total_wait_duration >= timeout
      raise "Redis LOCK LOCKED #{key} #{start_at}"
    end
  end
end
