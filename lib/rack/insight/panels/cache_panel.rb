module Rack::Insight

  class CachePanel < Panel
    require "rack/insight/panels/cache_panel/panel_app"
    require "rack/insight/panels/cache_panel/stats"

    def request_start(env, start)
      @stats = Stats.new
    end

    def request_finish(env, st, hd, bd, timing)
      store(env, @stats)
    end

    def after_detect(method_call, timing, args, result)
      method, key = method_call.method, args.first
      if(defined? Dalli and Dalli::Client === method_call.object)
        method, key = args[0], args[1]
      end
      logger.info{ "Cache panel got #{method} #{key.inspect}" } if verbose(:high)
      @stats.record_call(method, timing.duration, !result.nil?, key) if method.present?
    end

    def panel_app
      PanelApp.new
    end

    def heading_for_request(number)
      stats = retrieve(number).first

      "Cache: %.2fms (#{stats.queries.size} calls)" % stats.time
    end

    def content_for_request(number)
      stats = retrieve(number).first
      render_template "panels/cache", :stats => stats
    end

  end

end
