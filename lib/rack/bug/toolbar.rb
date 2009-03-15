require "ipaddr"

require "rack/bug/panels/timer_panel"
require "rack/bug/panels/env_panel"
require "rack/bug/panels/sql_panel"
require "rack/bug/panels/log_panel"
require "rack/bug/panels/templates_panel"
require "rack/bug/panels/cache_panel"
require "rack/bug/panels/rails_info_panel"
require "rack/bug/panels/active_record_panel"
require "rack/bug/panels/memory_panel"

module Rack
  module Bug
    
    class Toolbar
      MIME_TYPES = ["text/html", "application/xhtml+xml"]
      
      def initialize(app, options = {})
        @app = app
        @options = options
      end
      
      def call(env)
        @env = env
        @env["rack.bug.panels"] ||= []
        
        status, headers, body = builder.call(env)
        response = Rack::Response.new(body, status, headers)
        
        inject_into(response) if modify?(env, response)
        return response.to_a
      end
      
      def modify?(env, response)
        !response.server_error? &&
        env["X-Requested-With"] != "XMLHttpRequest" &&
        MIME_TYPES.include?(response.content_type) &&
        (!ip_mask || ip_mask.include?(IPAddr.new(env["REMOTE_ADDR"]))) &&
        (!password || Request.new(env).cookies["rack_bug_password"] == @options[:password])
      end
      
      def password
        @options[:password]
      end
      
      def builder
        builder = Rack::Builder.new
        panel_classes.each do |panel_class|
          builder.use panel_class
        end
        builder.run @app
        return builder
      end
      
      def panel_classes
        [
          RailsInfoPanel,
          TimerPanel,
          EnvPanel,
          SQLPanel,
          ActiveRecordPanel,
          CachePanel,
          TemplatesPanel,
          LogPanel,
          MemoryPanel
        ]
      end
      
      def inject_into(response)
        full_body = response.body.join
        full_body.sub! /<\/body>/, render + "</body>"
        
        response["Content-Length"] = full_body.size.to_s
        response.body = [full_body]
      end
      
      def render
        @panels = @env["rack.bug.panels"].reverse
        @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/../bug/views/bug.html.erb")
        @template.result(binding)
      # rescue
      #   @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/../bug/views/error.html.erb")
      #   @template.result(binding)
      end
      
      def ip_mask
        return nil unless @options[:ip_mask]
        IPAddr.new(@options[:ip_mask])
      end
      
    end
    
  end
end