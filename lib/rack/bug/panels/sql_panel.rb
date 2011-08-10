require "digest"

module Rack
  class Bug

    class SQLPanel < Panel

      autoload :PanelApp, "rack/bug/panels/sql_panel/panel_app"
      autoload :QueryResult,    "rack/bug/panels/sql_panel/query"

      def initialize(app)
        super
        probe(self) do
          instrument "ActiveRecord::ConnectionAdapters::AbstractAdapter" do
            instance_probe :log
          end
        end
        table_setup("sql_queries")
        key_sql_template("")
      end

      def self.panel_mappings
        { "sql" => PanelApp.new }
      end

      def after_detect(method_call, timing, arguments, results)
        QueryResult.new(arguments.first, timing.duration, method_call.backtrace, results)
      end

      def self.record(sql, backtrace = [])
        return yield unless Rack::Bug.enabled?

        start_time = Time.now

        result = nil
        begin
          result = yield
        ensure
          queries << QueryResult.new(sql, Time.now - start_time, backtrace, result)
        end

        return result
      end

      def self.record_event(sql, duration, backtrace = [])
        return unless Rack::Bug.enabled?
        queries << QueryResult.new(sql, duration, backtrace)
      end

      def self.reset
        Thread.current["rack.test.queries"] = []
      end

      def self.queries
        Thread.current["rack.test.queries"] ||= []
      end

      def self.total_time
        (queries.inject(0) do |memo, query|
          memo + query.time
        end) * 1_000
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
