module Rack::Insight

  class MongoPanel < Panel
    require "rack/insight/panels/mongo_panel/mongo_extension"
    require "rack/insight/panels/mongo_panel/stats"

    self.has_table = false

    def self.record(command, &block)
      return block.call unless Rack::Insight.enabled?

      start_time = Time.now
      result = block.call
      total_time = Time.now - start_time
      stats.record_call(total_time * 1_000, command)
      return result
    end

    def self.reset
      Thread.current["rack-insight.mongo"] = Stats.new
    end

    def self.stats
      Thread.current["rack-insight.mongo"] ||= Stats.new
    end

    def heading
      "Mongo: %.2fms (#{self.class.stats.queries.size} calls)" % self.class.stats.time
    end

    def content
      result = render_template "panels/mongo", :stats => self.class.stats
      self.class.reset
      return result
    end

  end

end
