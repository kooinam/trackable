class BackgroundJob
  include BaseModel

  field :klass, type: String
  field :action, type: String
  field :record_id, type: String
  field :enqueued_at, type: DateTime
  field :delay, type: Integer
  field :expire_at, type: DateTime
  field :running, type: Boolean, default: false
  field :runned_at, type: DateTime
  field :job_id, type: String
  field :queue, type: String

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
    expire_at: 1,
  }, {
    background: true,
  })

  validates_presence_of :klass, :action, :record_id, :enqueued_at

  def self.cleanup
    expiration = DateTime.now

    background_jobs = BackgroundJob.where(:expire_at.lte => expiration)

    if background_jobs.count > 0
      resultable = Resultable.new
      resultable.message = "#{background_jobs.count} BackgroundJob expired!!!"
      resultable.parameters[:background_job_ids] = background_jobs.map(&:id).join(', ')

      AdminMailer.delay.resultable_error(resultable)
    end
  end

  def self.enqueue(klass, action, record_id = 0, delay: nil, queue: 'default', running: false, execute_now: false)
    AwryThread.new execute_now: execute_now do
      key = "background-job-#{klass.to_s}-#{action}-#{record_id}"

      if RedisLock.lock(key, lock: false)
        background_jobs = self.grab_all(klass.to_s, action, record_id, running: running)

        if background_jobs.empty?
          background_job = BackgroundJob.create(klass: klass.to_s, action: action, record_id: record_id, delay: delay, queue: queue)

          if Rails.env.test?
            RedisLock.unlock(key)
          end

          background_job.enqueue_to_sidekiq
        end

        RedisLock.unlock(key)
      end
    end
  end

  def self.grab_all(klass, action, record_id = 0, running: false)
    self.where(klass: klass, action: action, record_id: record_id, running: running)
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

  def enqueue_to_sidekiq
    klass_delay = nil

    if self.delay
      if self.queue
        klass_delay = BackgroundJob.delay_for(self.delay.seconds, queue: self.queue)
      else
        klass_delay = BackgroundJob.delay_for(self.delay.seconds)
      end
    else
      if self.queue
        klass_delay = BackgroundJob.delay(queue: self.queue)
      else
        klass_delay = BackgroundJob.delay
      end
    end

    job_id = klass_delay.execute(self.id, self.klass, self.action.to_s, self.record_id)

    if job_id
      delay = self.delay || 0
      enqueued_at = DateTime.now
      expire_at = enqueued_at + delay.seconds + 10.seconds

      self.update(job_id: job_id, enqueued_at: enqueued_at, expire_at: expire_at)
    end
  end
end
