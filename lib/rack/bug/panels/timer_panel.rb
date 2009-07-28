require "benchmark"

module Rack
  module Bug
    
    class TimerPanel < Panel
      
      def name
        "timer"
      end
      
      def call(env)
        status, headers, body = nil
        @times = Benchmark.measure do
          status, headers, body = @app.call(env)
        end
        
        @measurements = [
          ["User CPU time",   "%.2fms" % (@times.utime * 1_000)],
          ["System CPU time", "%.2fms" % (@times.stime * 1_000)],
          ["Total CPU time",  "%.2fms" % (@times.total * 1_000)],
          ["Elapsed time",    "%.2fms" % (@times.real  * 1_000)]
        ]
        
        env["rack-bug.panels"] << self
        return [status, headers, body]
      end
      
      def heading
        "%.2fms" % (@times.real * 1_000)
      end
      
      def content
        render_template "panels/timer", :measurements => @measurements
      end
      
    end
    
  end
end