require "rack/bug/extensions/rails_extension"

module Rack
  module Bug
    
    class LogPanel < Panel
      
      def self.record(message)
        return unless message
        Thread.current["rack.bug.logs"] ||= []
        Thread.current["rack.bug.logs"] << message
      end
      
      def self.reset
        Thread.current["rack.bug.logs"] = []
      end
      
      def self.logs
        Thread.current["rack.bug.logs"] || []
      end
      
      def name
        "log"
      end
      
      def heading
        "Log"
      end

      def content
        @logs = self.class.logs
        @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/../views/panels/log.html.erb")
        result = @template.result(binding)
        self.class.reset
        return result
      end
      
    end
    
  end
end
