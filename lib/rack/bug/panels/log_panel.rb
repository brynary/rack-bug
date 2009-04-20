require "rack/bug/panels/log_panel/rails_extension"

module Rack
  module Bug
    
    class LogPanel < Panel
      
      def self.record(*args)
        return unless Rack::Bug.enabled?
        return unless args
        logs << [args[1], args[0]]
      end
      
      def self.reset
        Thread.current["rack.bug.logs"] = []
      end
      
      def self.logs
        Thread.current["rack.bug.logs"] ||= []
      end
      
      def name
        "log"
      end
      
      def heading
        "Log"
      end

      def content
        result = render_template "panels/log", :logs => self.class.logs
        self.class.reset
        return result
      end
      
    end
    
  end
end
