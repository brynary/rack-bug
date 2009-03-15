require "rack/bug/app"
require "rack/bug/toolbar"
require "rack/bug/options"

module Rack
  module Bug
    
    class Middleware
      include Rack::Bug::Options
      
      def initialize(app, options = {}, &block)
        @app = app
        initialize_options options
        instance_eval(&block) if block_given?
      end
    
      def call(env)
        @env = @default_options.merge(env)
        cascade.call(env)
      end
      
      def cascade
        Rack::Cascade.new([Rack::Bug::App.new, Toolbar.new(asset_server, @env)])
      end
      
      def asset_server
        Rack::Static.new(@app, :urls => ["/__rack_bug__"], :root => public_path)
      end
      
      def public_path
        ::File.expand_path(::File.dirname(__FILE__) + "/../bug/public")
      end
      
    end
    
  end
end