class AdminMailer < ApplicationMailer
  def resultable_error(resultable)
    @resultable = resultable

    subject = "#{Rails.application.class.name} #{Rails.application.secrets.redis_namespace}: Resultable Error - #{@resultable.message}"

    mail(to: SettingsManager.singleton.admin_email, subject: subject, from: SettingsManager.singleton.sender_email, bcc: SettingsManager.singleton.bcc_email)
  end
end
