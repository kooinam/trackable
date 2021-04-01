module Trackable
  module Locks
    class RedisLock
      extend ActiveSupport::Concern

      cattr_accessor :redis_url, :redis_password, :redis_port, :redis_timeout, :redis_namespace

      attr_accessor :lock_key, :lock_expiry, :lock_timeout, :start_at

      def self.configure(redis_url: "redis://localhost", redis_password: nil, redis_port: "6379", redis_timeout: 10, redis_namespace: nil)
        self.redis_url = redis_url
        self.redis_password = redis_password
        self.redis_port = redis_port
        self.redis_timeout = redis_timeout
        self.redis_namespace = redis_namespace
      end

      def self.wait_lock(lock_key, wait: true, lock_expiry: 10, lock_timeout:nil, &block)
        lock = Trackable::Locks::RedisLock.new(lock_key, lock_expiry: lock_expiry, lock_timeout: lock_timeout)
        lock_value = lock.acquire_lock(wait)

        if lock_value
          block.call
        end

        lock.release_lock(lock_value)
        lock.close
      end

      def self.lock(lock_key, wait: true, lock_expiry: 10, lock_timeout:nil)
        lock = Trackable::Locks::RedisLock.new(lock_key, lock_expiry: lock_expiry, lock_timeout: lock_timeout)
        
        lock.acquire_lock(wait)
      end

      def initialize(lock_key, lock_expiry: 10, lock_timeout: nil)
        self.lock_key = lock_key
        self.lock_expiry = lock_expiry
        self.lock_timeout = lock_timeout
      end

      def redis
        if self.class.redis_url.nil? or self.class.redis_namespace.nil?
          raise "Redis Lock is not configured"
        end

        if @nsp.nil?
          redis = Redis.new(
            url: self.class.redis_url,
            password: self.class.redis_password,
            port: self.class.redis_port,
            timeout: self.class.redis_timeout,
          )

          @nsp = Redis::Namespace.new(self.class.redis_namespace, redis: redis)
        end

        @nsp.redis
      end

      def acquire_lock(wait)
        self.start_at = Time.now
        lock_value = SecureRandom.hex

        if wait
          wait_duration = 0.01
          total_wait_duration = 0

          # if the key is exist, keep waiting until it release
          while redis.set(self.lock_key, lock_value, nx: true, ex: self.lock_expiry) == false
            total_wait_duration += wait_duration
            check_timeout(total_wait_duration)

            sleep wait_duration
          end
        else
          acquired = redis.set(self.lock_key, lock_value, nx: true, ex: self.lock_expiry)

          if !acquired
            lock_value = nil
          end
        end

        # only return lock value if lock is acquired
        lock_value
      end

      def release_lock(lock_value)
        if self.redis.get(self.lock_key) == lock_value
          self.redis.del(self.lock_key)
        end
      end

      def close
        self.redis.close
      end

      private

      def check_timeout(total_wait_duration)
        if self.lock_timeout.nil?
          return
        end

        if total_wait_duration >= self.lock_timeout
          raise "Redis LOCK TIME OUT #{self.lock_key} #{self.start_at}"
        end
      end
    end
  end
end
