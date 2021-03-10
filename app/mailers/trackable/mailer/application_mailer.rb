module Trackable
  module Mailer
    class ApplicationMailer < ActionMailer::Base
      include Trackable::Mailer::Base

      default from: "from@example.com"
      layout "mailer"
    end
  end
end
