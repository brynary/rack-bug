require "erb"

module Rack
  module Bug
    
    # Panels are also Rack middleware
    class Panel
      include Render
      include ERB::Util
      
      attr_reader :request
      
      def initialize(app)
        if panel_app
          @app = Rack::Cascade.new([panel_app, app])
        else
          @app = app
        end
      end
      
      def call(env)
        before(env)
        status, headers, body = @app.call(env)
        @request = Request.new(env)
        after(env, status, headers, body)
        env["rack-bug.panels"] << self
        return [status, headers, body]
      end
      
      def panel_app
        nil
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