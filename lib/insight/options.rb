require 'ipaddr'

module Insight
  module Options
    class << self
      private
      def option_accessor(key)
        define_method(key) { || read_option(key) }
        define_method("#{key}=") { |value| write_option(key, value) }
        define_method("#{key}?") { || !! read_option(key) }
      end
    end

    option_accessor :secret_key
    option_accessor :ip_masks
    option_accessor :password
    option_accessor :panel_classes
    option_accessor :intercept_redirects
    option_accessor :database_path

    # The underlying options Hash. During initialization (or outside of a
    # request), this is a default values Hash. During a request, this is the
    # Rack environment Hash. The default values Hash is merged in underneath
    # the Rack environment before each request is processed.
    def options
      @env || @default_options
    end

    # Set multiple options.
    def options=(hash={})
      hash.each { |key,value| write_option(key, value) }
    end

    # Set an option. When +option+ is a Symbol, it is set in the Rack
    # Environment as "rack-cache.option". When +option+ is a String, it
    # exactly as specified. The +option+ argument may also be a Hash in
    # which case each key/value pair is merged into the environment as if
    # the #set method were called on each.
    def set(option, value=self, &block)
      if block_given?
        write_option option, block
      elsif value == self
        self.options = option.to_hash
      else
        write_option option, value
      end
    end

    private

    def read_option(key)
      options[option_name(key)]
    end

    def write_option(key, value)
      options[option_name(key)] = value
    end

    def option_name(key)
      case key
      when Symbol ; "insight.#{key}"
      when String ; key
      else raise ArgumentError
      end
    end

    def process_options
      if(file_list = read_option('insight.panel_files'))
        class_list = read_option('insight.panel_classes') || []
        file_list.each do |file|
          class_list |= Insight::Panel.from_file(file)
        end
        write_option('insight.panel_classes', class_list)
      end

      Insight::Database.database_path = read_option('insight.database_path')
    end

    def initialize_options(options=nil)
      @default_options = {
        'insight.ip_masks'             =>  [IPAddr.new("127.0.0.1")],
        'insight.password'             =>  nil,
        'insight.verbose'              =>  nil,
        'insight.secret_key'           =>  nil,
        'insight.intercept_redirects'  =>  false,
        'insight.panels'               =>  [],
        'insight.log_level'            =>  Logger::INFO,
        'insight.log_path'             =>  "log/insight.log",
        'insight.database_path'        =>  "insight.sqlite",
        'insight.panel_files'          =>  %w{
          rails_info_panel
          timer_panel
          request_variables_panel
          sql_panel
          active_record_panel
          cache_panel
          templates_panel
          log_panel
          memory_panel
        }
      }
      self.options = options || {}
      process_options
    end

  end
end
