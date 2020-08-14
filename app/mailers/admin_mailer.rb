class AdminMailer < ApplicationMailer
  def resultable_error(resultable)
    @resultable = resultable

    subject = "#{Rails.application.class.name} #{Rails.application.secrets.redis_namespace}: Resultable Error - #{@resultable.message}"

    mail(to: NotificationManager.singleton.admin_email, subject: subject, from: NotificationManager.singleton.sender_email, bcc: NotificationManager.singleton.bcc_email)
  end
end
