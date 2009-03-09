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
        @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/../views/panels/env.html.erb")
        @template.result(binding)
      end

    end
    
  end
end