json.(attachment, :created_at)

json.type attachment._type

# json.url image_path(image_attachment.attachment.url(:original))

# Spree::ImageAttachment.attachment_definitions[:attachment][:styles].each do |k,v|
#   json.set!("#{k}_url", image_path(image_attachment.attachment.url(k)))
# end

if attachment.is_a? ImageAttachment
  attachment.content.versions.keys.each do |key|
    url = attachment.content.try(key.to_sym).try(:url)

    if url[0] == '/'
      json.set! "#{key}_url", "#{Rails.application.secrets.host}#{url}"
    else
      json.set! "#{key}_url", url
    end
  end
end

if defined?(no_id).nil?
  json.id attachment.id.to_s
end
