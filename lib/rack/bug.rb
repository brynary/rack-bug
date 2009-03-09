require "rubygems"

unless $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__) + "/.."))
  $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/.."))
end

require "rack/bug/toolbar"
require "rack/bug/panels/timer_panel"
require "rack/bug/panels/env_panel"
require "rack/bug/panels/sql_panel"
require "rack/bug/panels/log_panel"
require "rack/bug/panels/templates_panel"

module Rack
  module Bug
    
    VERSION = "0.1.0"
    
    class Middleware
      
      def initialize(app)
        @app = app
      end
    
      def call(env)
        toolbar = Toolbar.new(asset_server)
        toolbar.call(env)
      end
      
      def asset_server
        Rack::Static.new(@app, :urls => ["/__rack_bug__"], :root => public_path)
      end
      
      def public_path
        ::File.expand_path(::File.dirname(__FILE__) + "/bug/public")
      end
      
    end
    
  end
end