module Rack::Bug

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
      when Symbol ; "rack-bug.#{key}"
      when String ; key
      else raise ArgumentError
      end
    end

    def initialize_options(options={})
      @default_options = {
        'rack-bug.ip_masks' => [IPAddr.new("127.0.0.1")],
        'rack-bug.password' => nil,
        'rack-bug.verbose'  => nil,
        'rack-bug.secret_key' => nil,
        'rack-bug.intercept_redirects' => false,
        'rack-bug.panels' => [],
        'rack-bug.panel_classes' => [
          RailsInfoPanel,
          TimerPanel,
          RequestVariablesPanel,
          SQLPanel,
          ActiveRecordPanel,
          CachePanel,
          TemplatesPanel,
          LogPanel,
          MemoryPanel
        ]
      }
      self.options = options
    end

  end
end
