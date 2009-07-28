require "rack/bug/panels/cache_panel/memcache_extension"

module Rack
  module Bug

    class CachePanel < Panel
      autoload :PanelApp, "rack/bug/panels/cache_panel/panel_app"
      autoload :Stats,    "rack/bug/panels/cache_panel/stats"

      def self.record(method, *keys, &block)
        return block.call unless Rack::Bug.enabled?

        start_time = Time.now
        result = block.call
        total_time = Time.now - start_time
        hit = result.nil? ? false : true
        stats.record_call(method, total_time * 1_000, hit, *keys)
        return result
      end

      def self.reset
        Thread.current["rack.bug.cache"] = Stats.new
      end

      def self.stats
        Thread.current["rack.bug.cache"] ||= Stats.new
      end

      def panel_app
        PanelApp.new
      end

      def name
        "cache"
      end

      def heading
        "Cache: %.2fms (#{self.class.stats.queries.size} calls)" % self.class.stats.time
      end

      def content
        result = render_template "panels/cache", :stats => self.class.stats
        self.class.reset
        return result
      end

    end

  end
end