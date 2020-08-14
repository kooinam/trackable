class MassMailer < ActionMailer::Base
  layout 'mailer'

  def export(email, params)
    @params = params

    subject = "#{DateTime.current.prettify} Export #{params[:name]}"

    xlsx = render_to_string handlers: [:axlsx], formats: [:xlsx], template: "/export/index", locals: {
      params: @params,
    }, layout: false
    attachment = Base64.encode64(xlsx)
    attachments["#{DateTime.current.strftime('%d %b %Y %T %p')} #{@params[:name]}.xlsx"] = {
      mime_type: Mime[:xlsx],
      content: attachment,
      encoding: 'base64',
    }

    mail(to: email, subject: subject, from: NotificationManager.singleton.sender_email, bcc: NotificationManager.singleton.bcc_email)
  end

  def import(success, email, params)
    @success = success
    @params = params

    subject = nil
    if success
      subject = 'Import Successfully'
    else
      subject = 'Failed to Import'
    end

    mail(to: email, subject: subject, from: NotificationManager.singleton.sender_email, bcc: NotificationManager.singleton.bcc_email)
  end
end
