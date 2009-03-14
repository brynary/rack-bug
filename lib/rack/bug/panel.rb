require "erb"

module Rack
  module Bug
    
    # Panels are also Rack middleware
    class Panel
      include ERB::Util
      
      def initialize(app)
        @app = app
      end
      
      def call(env)
        before(env)
        status, headers, body = @app.call(env)
        after(env, status, headers, body)
        env["rack.bug.panels"] << self
        return [status, headers, body]
      end
      
      def has_content?
        true
      end
      
      def before(env)
      end
      
      def after(env, status, headers, body)
      end
      
      def render(template)
      end
      
    end
    
  end
end