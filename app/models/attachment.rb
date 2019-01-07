class Attachment
  include BaseModel

  belongs_to :attachmentable, polymorphic: true, index: true, optional: true

  field :uuid, type: String
  field :key, type: String

  before_save :assign_uuid

  private
  def assign_uuid
    if self.uuid.nil?
      self.uuid = SecureRandom.hex
    end
  end
end
