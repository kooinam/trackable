json.attachment do
  json.partial! '/api/attachments/attachment', attachment: @attachment
end
