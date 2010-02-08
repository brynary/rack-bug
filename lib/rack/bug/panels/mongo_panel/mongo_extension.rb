require 'mongo'

if defined?(Mongo)
  Mongo::Connection.class_eval do

    def send_message_with_rack_bug(operation, message, log_message)
      Rack::Bug::MongoPanel.record(log_message) do
        send_message_without_rack_bug(operation, message, log_message)
      end
    end

    def receive_message_with_rack_bug(operation, message, log_message, socket)
      Rack::Bug::MongoPanel.record(log_message) do
        receive_message_without_rack_bug(operation, message, log_message, socket)
      end
    end
  
    alias_method_chain :receive_message, :rack_bug
  end
end
