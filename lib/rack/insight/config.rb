module Rack::Insight
  class Config
    class << self
      attr_accessor :config
    end

    DEFAULTS = {
      # You can augment or replace the default set of panel load paths.
      # These are the paths where rack-insight will look for panels.
      # A rack-insight extension gem could place panels in:
      #   lib/foo/bar/
      # Since gems' lib/ is automatically shifted onto Ruby load path, this will make the custom panels discoverable:
      #   Rack::Insight::Config.configure do |config|
      #     config[:panel_load_paths] << File::join('foo', 'bar')
      #   end
      :panel_load_paths => [File::join('rack', 'insight', 'panels')]
    }

    #cattr_reader :config
    #cattr_writer :config

    @config ||= DEFAULTS
    def self.configure &block
      yield @config
      unless config[:panel_load_paths].kind_of?(Array)
        raise "Rack::Insight::Config.config[:panel_load_paths] is invalid: Expected kind of Array but got #{config[:panel_load_paths].class}"
      end
    end
  end
end
