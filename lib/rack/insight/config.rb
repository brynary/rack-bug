require 'logger' # Require the standard Ruby Logger
begin
  require 'redis'
rescue LoadError
  warn "Could not load redis ruby gem. Some features are disabled."
end

module Rack::Insight
  class Config

    VERBOSITY = {
      :debug => Logger::DEBUG,
      :high => Logger::INFO,
      :med => Logger::WARN,
      :low => Logger::ERROR,
      # Silent can be used with unless instead of if.  Example:
      #   logger.info("some message") unless app.verbose(:silent)
      :silent => Logger::FATAL
    }

    class << self
      attr_reader :config, :verbosity, :log_file, :log_level, :rails_log_copy,
                  :filtered_backtrace, :panel_configs, :silence_magic_insight_warnings,
                  :database, :handle_javascript
    end
    @log_file = STDOUT
    @log_level = ::Logger::DEBUG
    @logger = nil
    @verbosity = nil
    @rails_log_copy = true
    @filtered_backtrace = true
    @panel_configs = {
      :active_record => {:probes => {'ActiveRecord::Base' => [:class, :allocate]}},
      :active_resource => {:probes => {'ActiveResource::Connection' => [:instance, :request]}},
      :cache => {:probes => { 'Memcached'     => [:instance, :decrement, :get, :increment, :set,
                                                                 :add, :replace, :delete, :prepend, :append],
                              'MemCache'      => [:instance, :decr, :get, :get_multi, :incr, :set, :add, :delete],
                              'Dalli::Client' => [:instance, :perform] } },
#      :log_panel => The log panel configures its probes in its initializer
      :sphinx => {:probes => {'Riddle::Client' => [:instance, :request]}},
      :sql => {:probes => Hash[%w{ PostgreSQLAdapter MysqlAdapter SQLiteAdapter
                  Mysql2Adapter OracleEnhancedAdapter }.map do |adapter|
                    ["ActiveRecord::ConnectionAdapters::#{adapter}", [:instance, :execute, :exec_query]]
                  end ] },
      :templates => {:probes => {'ActionView::Template' => [:instance, :render]}},
      :redis => {:probes => defined?(Redis::Client) ?
        { 'Redis::Client' => [:instance, :call] } : # Redis >= 3.0.0
        { 'Redis' => [:instance, :call_command] } # Redis < 3.0.0
      }
    }

    @silence_magic_insight_warnings = false
    @database = {
      :raise_encoding_errors => false,  # Either way will be logged
      :raise_decoding_errors => true,   # Either way will be logged
    }
    @handle_javascript = true # Set false if you want to handle the javascript yourself.

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
      :verbosity => @verbosity,
      :log_file => @log_file,
      :log_level => @log_level,
      :rails_log_copy => @rails_log_copy, # Only has effect when logger is the Rack::Insight::Logger, or a logger behaving like it
      # Can set a specific verbosity: Rack::Insight::Logging::VERBOSITY[:debug]
      :verbosity => @verbosity, # true is equivalent to relying solely on the log level of each logged message
      :filtered_backtrace => @filtered_backtrace, # Full back-traces, or filtered ones?
      :panel_configs => @panel_configs, # Allow specific panels to have their own configurations, and make it extensible
      :silence_magic_insight_warnings => @silence_magic_insight_warnings, # Should Rack::Insight warn when the MagicInsight is used?
      :database => @database, # a hash.  Keys :raise_encoding_errors, and :raise_decoding_errors are self explanatory
                             # :raise_encoding_errors
                             #    When set to true, if there is an encoding error (unlikely)
                             #    it will cause a 500 error on your site.  !!!WARNING!!!
                             # :raise_decoding_errors
                             #    The bundled panels should work fine with :raise_decoding_errors set to true or false
                             #    but custom panel implementations may prefer one over the other
                             #    The bundled panels will capture these errors and perform admirably.
                             #    Site won't go down unless a custom panel is not handling the errors well.
      :handle_javascript => @handle_javascript # If Your setup is AMD, and you are handling your javascript module loading,
                             # including that of jQuery, then you will need to set this to false.
    }

    @config ||= DEFAULTS
    def self.configure &block
      yield @config
      logger.debug("Rack::Insight::Config#configure:\n  called from: #{caller[0]}\n  with: #{@config}") if config[:verbosity] == true || config[:verbosity].respond_to?(:<) && config[:verbosity] <= 1
      @logger = config[:logger]
      if @logger.nil?
        @log_level = config[:log_level]
        @log_file = config[:log_file]
      elsif config[:log_level] || config[:log_file]
        logger.warn("Rack::Insight::Config#configure: when logger is set, log_level and log_file have no effect, and will only confuse you.")
      end
      @verbosity = config[:verbosity]
      if @verbosity.nil?
        @verbosity = Rack::Insight::Config::VERBOSITY[:silent]
      end
      @filtered_backtrace = config[:filtered_backtrace]
      @silence_magic_insight_warnings = config[:silence_magic_insight_warnings]
      @database = config[:database]
      @handle_javascript = !!config[:handle_javascript] # Cast to boolean

      config[:panel_configs].each do |panel_name_sym, config|
        set_panel_config(panel_name_sym, config)
      end

      validate_config(:panel_configs, Hash)
      validate_config(:panel_load_paths, Array)
      validate_config(:database, Hash)
    end

    def self.validate_config(key, klass)
      raise ConfigurationError.new(key, klass.to_s) unless config[key].kind_of?(klass)
    end

    class ConfigurationError < StandardError;
      def self.new(key, expected)
        actual = Rack::Insight::Config.config[key].class
        super("Rack::Insight::Config.config[:#{key}] is invalid: Expected kind of #{expected} but got #{actual}")
      end
    end

    # To preserve :panel_configs settings from extension libraries,
    # and allowing user config to override the defaults set in this, or other extension gems.
    def self.set_panel_config(panel_name_sym, config)
      @panel_configs[panel_name_sym].merge!(config)
      self.config[:panel_configs][panel_name_sym] = @panel_configs[panel_name_sym]
    end

    def self.verbosity
      @verbosity ||= self.config[:verbosity]
    end

    def self.logger
      @logger ||= begin
        logga = self.config[:logger]
        if logga.nil?
          warn ("Rack::Insight::Config#configure: logger is not configured, defaults to Ruby's Logger")
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
