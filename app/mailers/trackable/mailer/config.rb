module Trackable
  module Mailer 
    class Config
      attr_accessor :subject_prefix
      attr_accessor :sender_email
      attr_accessor :recipient_emails
      attr_accessor :bcc_emails
    end
  end
end