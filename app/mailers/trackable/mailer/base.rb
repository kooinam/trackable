module Trackable
  module Mailer
    module Base
      extend ActiveSupport::Concern

      class_methods do
        def setup(&block)
          block.call(mailer_config)
        end

        def mailer_config
          @@mailer_config ||= Trackable::Mailer::Config.new
        end
      end

      def mailer_config
        self.class.mailer_config
      end
    end
  end
end
