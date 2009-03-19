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
        "Request Vars"
      end
      
      def content
        render_template "panels/request_variables", :request => @request
      end

    end
    
  end
end