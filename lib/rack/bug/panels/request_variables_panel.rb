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
        render_template "panels/requeest_variables", :env => @env
      end

    end
    
  end
end