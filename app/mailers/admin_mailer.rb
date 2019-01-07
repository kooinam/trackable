class AdminMailer < ApplicationMailer
  def sidekiq_error(exception)
    @exception = exception

    subject = "Sidekiq Error - #{exception}"

    mail(to: SettingsManager.singleton.admin_email, subject: subject, from: SettingsManager.singleton.sender_email, bcc: SettingsManager.singleton.bcc_email)
  end
end
