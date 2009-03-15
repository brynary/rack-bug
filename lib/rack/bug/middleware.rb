require "rack/bug/app"
require "rack/bug/toolbar"

module Rack
  module Bug
    
    class Middleware
      
      def initialize(app, options = {})
        @app = app
        @options = options
      end
    
      def call(env)
        cascade.call(env)
      end
      
      def cascade
        Rack::Cascade.new([Rack::Bug::App.new, Toolbar.new(asset_server, @options)])
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