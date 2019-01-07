class Api::AttachmentsController < ActionController::Base
  include Api::Trackable

  def create
    if params[:file].content_type == 'text/plain'
      @attachment = TextAttachment.new(attachment_params)
    elsif params[:file].content_type == 'image/jpeg' or params[:file].content_type == 'image/png'
      @attachment = ImageAttachment.create(attachment_params)
    elsif params[:file].content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" or params[:file].content_type == 'application/vnd.ms-excel'
      @attachment = SpreadsheetAttachment.new(attachment_params)
    end

    if @attachment.save
      render '/api/attachments/show'
    else
      invalid_resource!(@attachment)
    end
  end

  private
  def attachment_params
    {
      content: params[:file],
    }
  end
end
