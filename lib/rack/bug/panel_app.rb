module Rack
  module Bug
    
    class PanelApp
      include Rack::Bug::Render
      
      attr_reader :request
      
      def call(env)
        @request = Rack::Request.new(env)
        dispatch
      end
      
      def render_template(*args)
        Rack::Response.new([super]).to_a
      end
      
      def params
        @request.GET
      end

      def not_found
        [404, {}, []]
      end
      
    end
    
  end
end