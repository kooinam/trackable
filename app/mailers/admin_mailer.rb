class AdminMailer < ApplicationMailer
  def sidekiq_error(exception, context = nil)
    @context = context
    @exception = exception

    subject = "Sidekiq Error - #{@exception}"

    mail(to: SettingsManager.singleton.admin_email, subject: subject, from: SettingsManager.singleton.sender_email, bcc: SettingsManager.singleton.bcc_email)
  end

  def resultable_error(resultable)
    @resultable = resultable

    subject = "Resultable Error - #{@resultable.message}"

    mail(to: SettingsManager.singleton.admin_email, subject: subject, from: SettingsManager.singleton.sender_email, bcc: SettingsManager.singleton.bcc_email)
  end
end
