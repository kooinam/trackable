require 'haml'

module Trackable
  class Engine < ::Rails::Engine
    engine_name 'trackable'

    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += %W(#{config.root}/app)

    class << self
      def activate
        cache = Rails.application.config.cache_classes

        ['app', 'lib'].each do |dir|
          file = File.join(File.dirname(__FILE__), "../../#{dir}/**/*.rb")

          Dir.glob(file) do |c|
            if cache or c.include?('concerns')
              require(c)
            else
              load(c)
            end
          end
        end
      end
    end

    config.to_prepare &method(:activate).to_proc
  end

  def self.setup(&block)
    yield self
  end
end
