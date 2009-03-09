require "rack/bug/panel"
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
          ["User CPU time", "%.1fms" % (@times.utime * 1_000)],
          ["System CPU time", "%.1fms" % (@times.stime * 1_000)],
          ["Total CPU time", "%.1fms" % (@times.total * 1_000)],
          ["Elapsed time", "%.1fms" % (@times.real * 1_000)]
        ]
        
        env["rack.bug.panels"] << self
        return [status, headers, body]
      end
      
      def heading
        "%.1fms" % (@times.real * 1_000)
      end
      
      def content
        @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/../views/panels/timer.html.erb")
        @template.result(binding)
      end
      
    end
    
  end
end