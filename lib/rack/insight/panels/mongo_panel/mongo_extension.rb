require 'mongo'
if defined?(Mongo)
  Mongo::Connection.class_eval do

    def send_message_with_insight(operation, message, log_message=nil)
      Rack::Insight::MongoPanel.record(log_message || message) do
        send_message_without_insight(operation, message, log_message)
      end
    end
    alias_method_chain :send_message, :insight

    def send_message_with_safe_check_with_insight(operation, message, db_name, log_message=nil, last_error_params=false)
      Rack::Insight::MongoPanel.record(log_message || message) do
        send_message_with_safe_check_without_insight(operation, message, db_name, log_message, last_error_params)
      end
    end
    alias_method_chain :send_message_with_safe_check, :insight

    def receive_message_with_insight(operation, message, log_message=nil, socket=nil)
    end
  end
  alias_method_chain :receive_message, :insight
end

