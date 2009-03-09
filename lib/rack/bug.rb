require "rubygems"

unless $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__) + "/.."))
  $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/.."))
end

require "rack/bug/panels/timer_panel"
require "rack/bug/panels/env_panel"

module Rack
  module Bug
    
    class Middleware
      
      def initialize(app)
        @app = app
      end
    
      def call(env)
        @env = env
        @env["rack.bug.panels"] ||= []
        status, headers, body = builder.call(env)
        return debugged_response(env, status, headers, body)
      end
    
      def panel_classes
        [TimerPanel, EnvPanel]
      end
      
      def builder
        @builder = Rack::Builder.new
        
        panel_classes.each do |panel_class|
          @builder.use panel_class
        end
        
        dir = ::File.expand_path(::File.dirname(__FILE__) + "/bug/public")
        @builder.use Rack::Static, :urls => ["/__rack_bug__"], :root => dir
        @builder.run @app
        return @builder
      end
      
      def debugged_response(env, status, headers, body)
        output = []
        body.each do |body_fragment|
          output << body_fragment
        end
        full_output = output.join
        full_output.sub! /<body>/, "<body>" + html(env)
        headers["Content-Length"] = full_output.size.to_s
        return [status, headers, full_output]
      end
      
      def html(env)
        @panels = @env["rack.bug.panels"].reverse
        @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/bug/views/bug.html.erb")
        @template.result(binding)
      end
      
    end
    
  end
end