if defined?(ActiveRecord) && defined?(ActiveRecord::ConnectionAdapters)

  if defined?(ActiveSupport::Notifications)
    require 'active_record/base'
    ActiveSupport::Notifications.subscribe(/sql.active_record/) do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      Rack::Bug::SQLPanel.record_event(event.payload[:sql], event.duration) # TODO: is there any way to get a backtrace out of here?
    end
  else
  
    ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
      def log_with_rack_bug(sql, name, &block)
        Rack::Bug::SQLPanel.record(sql, Kernel.caller) do
          log_without_rack_bug(sql, name, &block)
        end
      end

      alias_method_chain :log, :rack_bug
    end
    
  end
end
