require 'mongo'

if defined?(Mongo)
  Mongo::Connection.class_eval do

    def send_message_with_rack_bug(operation, message, log_message=nil)
      Rack::Bug::MongoPanel.record(log_message || message) do
        send_message_without_rack_bug(operation, message, log_message)
      end
    end
    alias_method_chain :send_message, :rack_bug

    def send_message_with_safe_check_with_rack_bug(operation, message, db_name, log_message=nil, last_error_params=false)
      Rack::Bug::MongoPanel.record(log_message || message) do
        send_message_with_safe_check_without_rack_bug(operation, message, db_name, log_message, last_error_params)
      end
    end
    alias_method_chain :send_message_with_safe_check, :rack_bug

    def receive_message_with_rack_bug(operation, message, log_message=nil, socket=nil)
      Rack::Bug::MongoPanel.record(log_message || "A logger must be configured to catch receive message commands") do
        receive_message_without_rack_bug(operation, message, log_message, socket)
      end
    end
    alias_method_chain :receive_message, :rack_bug
  end
end
