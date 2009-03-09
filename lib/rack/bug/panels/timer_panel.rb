require "rack/bug/panel"

module Rack
  module Bug
    
    class TimerPanel < Panel
      
      def name
        "timer"
      end
      
      def before(env)
        @start_time = Time.now
      end
      
      def after(env, status, headers, body)
        @end_time = Time.now
      end
      
      def run_time
        @end_time - @start_time
      end
      
      def heading
        "%.1fms" % (run_time * 1_000)
      end
      
    end
    
  end
end