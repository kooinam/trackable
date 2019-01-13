class DevMessage
  include BaseModel

  field :message, type: String
  field :key, type: String
  field :important, type: Boolean, default: false

  def self.track(message, key, important: false)
    DevMessage.create(message: message, key: key, important: important)
  end

  def self.print(key, limit)
    DevMessage.where(key: key).order(created_at: :desc).limit(limit).each { |m| pp "#{DateTime.now} #{m.created_at} #{m.key} #{m.message}" }
  end

  def self.cleanup
    self.where(:created_at.lte => (DateTime.now - 5.minutes)).destroy_all
  end
end
