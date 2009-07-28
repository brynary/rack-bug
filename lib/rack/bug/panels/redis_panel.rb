module Rack
  module Bug

    class RedisPanel < Panel
      require "rack/bug/panels/redis_panel/redis_extension"

      autoload :Stats, "rack/bug/panels/redis_panel/stats"

      def self.record(*redis_command_args, &block)
        return block.call unless Rack::Bug.enabled?

        start_time = Time.now
        result = block.call
        total_time = Time.now - start_time
        stats.record_call(total_time * 1_000, redis_command_args)
        return result
      end

      def self.reset
        Thread.current["rack.bug.redis"] = Stats.new
      end

      def self.stats
        Thread.current["rack.bug.redis"] ||= Stats.new
      end

      def name
        "redis"
      end

      def heading
        "Redis: %.2fms (#{self.class.stats.queries.size} calls)" % self.class.stats.time
      end

      def content
        result = render_template "panels/redis", :stats => self.class.stats
        self.class.reset
        return result
      end

    end

  end
end