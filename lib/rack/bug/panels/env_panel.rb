module Rack
  module Bug
    
    class EnvPanel < Panel
      
      def name
        "env"
      end
      
      def before(env)
        @env = env
      end
      
      def heading
        "Rack Env"
      end
      
      def content
        render_template "panels/env", :env => @env
      end

    end
    
  end
end