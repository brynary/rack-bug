module Rack
  module Bug
    
    class RequestVariablesPanel < Panel
      
      def name
        "request_variables"
      end
      
      def before(env)
        @env = env
      end
      
      def heading
        "Rack Env"
      end
      
      def content
        render_template "panels/request_variables", :request => @request, :env => @env
      end

    end
    
  end
end