module Rack::Bug::LoggerExtension
  def self.included(target)
    target.send :alias_method, :add_without_rack_bug, :add
    target.send :alias_method, :add, :add_with_rack_bug
  end
  
  def add_with_rack_bug(*args, &block)
    logger_return = add_without_rack_bug(*args, &block)
    logged_message = logger_return
    logged_message = args[1] || args[2] unless logged_message.is_a?(String)
    Rack::Bug::LogPanel.record(logged_message, args[0])
    return logger_return
  end
end

if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
  logger = Rails.logger
elsif defined?(LOGGER)
  logger = LOGGER
end

if logger
  logger.class.send :include, Rack::Bug::LoggerExtension
end