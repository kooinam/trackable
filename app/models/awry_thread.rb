class AwryThread
  def self.new(execute_now: false, &block)
    if execute_now or Rails.env.test?
      block.call
    else
      Thread.new do
        begin
          block.call
        rescue Exception => e
          DevMessage.track("#{e} #{e.backtrace}", 'AwryThread', important: true)
        end
      end
    end
  end
end
