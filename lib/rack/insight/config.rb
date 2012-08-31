module Rack::Insight
  class Config
    class << self
      attr_reader :config, :verbosity, :log_file, :log_level, :rails_log_copy
    end
    @log_file = STDOUT
    @log_level = ::Logger::DEBUG
    @logger = nil
    @verbosity = true
    @rails_log_copy = true

    DEFAULTS = {
      # You can augment or replace the default set of panel load paths.
      # These are the paths where rack-insight will look for panels.
      # A rack-insight extension gem could place panels in:
      #   lib/foo/bar/
      # Since gems' lib/ is automatically shifted onto Ruby load path, this will make the custom panels discoverable:
      #   Rack::Insight::Config.configure do |config|
      #     config[:panel_load_paths] << File::join('foo', 'bar')
      #   end
      :panel_load_paths => [File::join('rack', 'insight', 'panels')],
      :logger => @logger,
      :log_file => @log_file,
      :log_level => @log_level,
      :rails_log_copy => @rails_log_copy, # Only has effect when logger is the Rack::Insight::Logger, or a logger behaving like it
      # Can set a specific verbosity: Rack::Insight::Logging::VERBOSITY[:debug]
      :verbosity => @verbosity # true is equivalent to relying soley on the log level of each logged message
    }

    @config ||= DEFAULTS
    def self.configure &block
      yield @config
      logger.debug("Config#configure:\n  called from: #{caller[0]}\n  with: #{@config}")
      @logger = config[:logger]
      @log_level = config[:log_level]
      @log_file = config[:log_file]
      @verbosity = config[:verbosity]
      unless config[:panel_load_paths].kind_of?(Array)
        raise "Rack::Insight::Config.config[:panel_load_paths] is invalid: Expected kind of Array but got #{config[:panel_load_paths].class}"
      end
    end

    def self.logger
      @logger ||= begin
        logga = self.config[:logger]
        if logga.nil?
          puts("Rack::Insight::Config#configure: logger is not configured, defaults to Ruby's Logger")
          logga = ::Logger.new(log_file)
          if logga.respond_to?(:level)
            logga.level = self.log_level
          elsif logga.respond_to?(:sev_threshold)
            logga.sev_threshold = self.log_level
          end
        end
        logga
      end
    end

  end
end
