if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
  module LoggingExtensions
    def add(*args, &block)
      logged_message = super
      Rack::Bug::LogPanel.record(logged_message, args[0])
      return logged_message
    end
  end

  Rails.logger.extend LoggingExtensions
end
