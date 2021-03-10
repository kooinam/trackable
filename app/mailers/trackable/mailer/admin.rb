module Trackable
  module Mailer
    class Admin < ApplicationMailer
      default :template_path => "admin_mailer"

      def resultable_error(resultable)

        @resultable = resultable

        subject = "#{mailer_config.subject_prefix}: Resultable Error - #{@resultable.message}"
        mail(
          subject: subject,
          from: mailer_config.sender_email,
          to: mailer_config.recipient_emails,
          bcc: mailer_config.bcc_emails || [],
        )
      end
    end
  end
end
