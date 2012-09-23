module Rack::Insight
  class SphinxPanel < Panel
    require "rack/insight/panels/sphinx_panel/stats"

    def request_start(env, start)
      @stats = Stats.new
    end

    def request_finish(env, status, headers, body, timing)
      store(env, @stats)
      @stats = nil
    end

    def after_detect(method_call, timing, args, message)
      @stats.record_call(timing.duration, args, method_call)
    end

    def heading_for_request(number)
      stats = retrieve(number).first
      "Sphinx: %.2fms (#{stats.queries.size} calls)" % stats.time
    end

    def content_for_request(number)
      render_template "panels/sphinx", :stats => retrieve(number).first
    end
  end
end
