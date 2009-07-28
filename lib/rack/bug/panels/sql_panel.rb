require "digest"

module Rack
  module Bug

    class SQLPanel < Panel
      require "rack/bug/panels/sql_panel/sql_extension"

      autoload :PanelApp, "rack/bug/panels/sql_panel/panel_app"
      autoload :Query,    "rack/bug/panels/sql_panel/query"

      def panel_app
        PanelApp.new
      end

      def self.record(sql, backtrace = [], &block)
        return block.call unless Rack::Bug.enabled?

        start_time = Time.now
        result = block.call
        queries << Query.new(sql, Time.now - start_time, backtrace)

        return result
      end

      def self.reset
        Thread.current["rack.test.queries"] = []
      end

      def self.queries
        Thread.current["rack.test.queries"] ||= []
      end

      def self.total_time
        (queries.inject(0) { |memo, query| memo + query.time}) * 1_000
      end

      def name
        "sql"
      end

      def heading
        "#{self.class.queries.size} Queries (%.2fms)" % self.class.total_time
      end

      def content
        result = render_template "panels/sql", :queries => self.class.queries
        self.class.reset
        return result
      end

    end

  end
end