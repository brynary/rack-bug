require 'benchmark'

module Rack::Insight
  class TimerPanel < Panel

    def call(env)
      status, headers, body = nil
      @times = Benchmark.measure do
        status, headers, body = @app.call(env)
      end

      store(env, [
            ["User CPU time",   "%.2fms" % (@times.utime * 1_000)],
            ["System CPU time", "%.2fms" % (@times.stime * 1_000)],
            ["Total CPU time",  "%.2fms" % (@times.total * 1_000)],
            ["Elapsed time",    "%.2fms" % (@times.real  * 1_000)]
      ])

      return [status, headers, body]
    end

    def heading_for_request(number)
      measurements = retrieve(number).first

      measurements.last.last
    end

    def content_for_request(number)
      render_template "panels/timer", :measurements => retrieve(number).first
    end

  end
end
