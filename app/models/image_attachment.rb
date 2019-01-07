class ImageAttachment < Attachment
  mount_uploader :content, ImageAttachmentUploader
end
