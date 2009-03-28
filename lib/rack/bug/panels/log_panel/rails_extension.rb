if defined?(Rails) && Rails.logger
  module LoggingExtensions
    def add(*args, &block)
      logged_message = super
      Rack::Bug::LogPanel.record(logged_message)
      return logged_message
    end
  end

  Rails.logger.extend LoggingExtensions
end