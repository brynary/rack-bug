module Rack::Insight
  class Config
    class << self
      attr_reader :config, :verbosity, :log_file, :log_level, :rails_log_copy,
                  :filtered_backtrace, :panel_configs, :silence_magic_insight_warnings
    end
    @log_file = STDOUT
    @log_level = ::Logger::DEBUG
    @logger = nil
    @verbosity = true
    @rails_log_copy = true
    @filtered_backtrace = true
    @panel_configs = {
      :active_record => {:probes => {'ActiveRecord' => [:class, :allocate]}},
      :active_resource => {:probes => {'ActiveResource::Connection' => [:instance, :request]}},
      :cache => {:probes => { 'Memcached'     => [:instance, :decrement, :get, :increment, :set,
                                                                 :add, :replace, :delete, :prepend, :append],
                              'MemCache'      => [:instance, :decr, :get, :get_multi, :incr, :set, :add, :delete],
                              'Dalli::Client' => [:instance, :perform] } },
      :active_record => {:probes => {'ActiveRecord' => [:class, :allocate]}},
#      :log_panel => The log panel configures its probes in its initializer
      :sql => {:probes => Hash[%w{ PostgreSQLAdapter MysqlAdapter SQLiteAdapter
                  Mysql2Adapter OracleEnhancedAdapter }.map do |adapter|
                    ["ActiveRecord::ConnectionAdapters::#{adapter}", [:instance, :execute]]
                  end ] },
      :templates => {:probes => {'ActionView::Template' => [:instance, :render]}}
    }
    @silence_magic_insight_warnings = false

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
      :verbosity => @verbosity, # true is equivalent to relying soley on the log level of each logged message
      :filtered_backtrace => @filtered_backtrace, # Full backtraces, or filtered ones?
      :panel_configs => @panel_configs, # Allow specific panels to have their own configurations, and make it extensible
      :silence_magic_insight_warnings => @silence_magic_insight_warnings # Should Rack::Insight warn when the MagicInsight is used?
    }

    @config ||= DEFAULTS
    def self.configure &block
      yield @config
      logger.debug("Rack::Insight::Config#configure:\n  called from: #{caller[0]}\n  with: #{@config}") if config[:verbosity] == true || config[:verbosity].respond_to?(:<) && config[:verbosity] <= 1
      @logger = config[:logger]
      @log_level = config[:log_level]
      @log_file = config[:log_file]
      @verbosity = config[:verbosity]
      @filtered_backtrace = config[:filtered_backtrace]
      @silence_magic_insight_warnings = config[:silence_magic_insight_warnings]

      config[:panel_configs].each do |panel_name_sym, config|
        set_panel_config(panel_name_sym, config)
      end

      unless config[:panel_load_paths].kind_of?(Array)
        raise "Rack::Insight::Config.config[:panel_load_paths] is invalid: Expected kind of Array but got #{config[:panel_load_paths].class}"
      end
      unless config[:panel_configs].kind_of?(Hash)
        raise "Rack::Insight::Config.config[:panel_configs] is invalid: Expected kind of Hash but got #{config[:panel_configs].class}"
      end
    end

    # To preserve :panel_configs settings from extension libraries,
    # and allowing user config to override the defaults set in this, or other extension gems.
    def self.set_panel_config(panel_name_sym, config)
      @panel_configs[panel_name_sym].merge!(config)
      self.config[:panel_configs][panel_name_sym] = @panel_configs[panel_name_sym]
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
