module Rack
  module Bug
    
    class Toolbar
      
      def initialize(app)
        @app = app
      end
      
      def call(env)
        @env = env
        @env["rack.bug.panels"] ||= []
        
        status, headers, body = builder.call(env)
        response = Rack::Response.new(body, status, headers)
        
        inject_into(response)
        return response.to_a
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
        [TimerPanel, EnvPanel, SQLPanel, CachePanel, LogPanel, TemplatesPanel]
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
      end
      
    end
    
  end
end