class BackgroundJob
  include BaseModel

  field :klass, type: String
  field :action, type: String
  field :record_id, type: String
  field :enqueued_at, type: DateTime
  field :delay, type: Integer
  field :tolerance, type: Integer, default: 3
  field :running, type: Boolean, default: false
  field :runned_at, type: DateTime

  index({
    klass: 1,
  }, {
    background: true,
  })

  index({
    action: 1,
  }, {
    background: true,
  })

  index({
    record_id: 1,
  }, {
    background: true,
  })

  index({
    running: 1,
  }, {
    background: true,
  })

  index({
    runned_at: 1,
  }, {
    background: true,
  })

  validates_presence_of :klass, :action, :record_id, :enqueued_at

  def self.enqueue(klass, action, record_id = 0, delay: nil, queue: nil, tolerance: 3, running: false, execute_now: false, notify: nil)
    AwryThread.new execute_now: execute_now do
      has_enqueued = false

      key = "background-job-#{klass}-#{action}-#{record_id}"

      if RedisLock.lock(key, lock: false)
        background_jobs = self.grab_all(klass, action, record_id, running: running).map do |background_job|
          if background_job.expired?
            nil
          else
            background_job
          end
        end.compact

        if background_jobs.empty?
          has_enqueued = true

          background_job = BackgroundJob.create(klass: klass.to_s, action: action, record_id: record_id, enqueued_at: DateTime.now, delay: nil, tolerance: tolerance)

          if Rails.env.test?
            RedisLock.unlock(key)
          end

          klass_delay = nil

          if delay
            if queue
              klass_delay = self.delay_for(delay.seconds, queue: queue)
            else
              klass_delay = self.delay_for(delay.seconds)
            end
          else
            if queue
              klass_delay = self.delay(queue: queue)
            else
              klass_delay = self.delay
            end
          end

          klass_delay.execute(background_job.id, klass.to_s, action.to_s, record_id)
        end

        RedisLock.unlock(key)
      end

      if notify == :executed
        if has_enqueued
          resultable = Resultable.new
          resultable.message = "#{klass.to_s} - #{action} - #{record_id} executed"

          AdminMailer.delay.resultable_error(resultable)
        end
      elsif notify == :unexecute
        if has_enqueued == false
          resultable = Resultable.new
          resultable.message = "#{klass.to_s} - #{action} - #{record_id} not executed"

          AdminMailer.delay.resultable_error(resultable)
        end
      end

      has_enqueued
    end
  end

  def self.grab_all(klass, action, record_id = 0, running: false)
    self.where(klass: klass.to_s, action: action, record_id: record_id, running: running)
  end

  def self.execute(background_job_id, klass = nil, action = nil, record_id = nil)
    background_job = self.where(id: background_job_id).first

    if background_job
      background_job.update(running: true, runned_at: DateTime.now)

      klass = background_job.klass.constantize

      if background_job.record_id == 0.to_s
        klass.send(background_job.action.to_sym, background_job)
      else
        klass.send(background_job.action.to_sym, background_job.record_id)
      end

      background_job.destroy
    end
  end

  def expired?
    expired_at = self.enqueued_at

    if self.delay
      expired_at += self.delay.seconds
    end

    if self.tolerance
      expired_at += self.tolerance.seconds
    end

    if DateTime.now >= expired_at
      true
    else
      false
    end
  end
end
