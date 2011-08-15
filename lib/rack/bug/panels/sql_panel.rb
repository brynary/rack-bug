require "digest"

module Rack
  class Bug

    class SQLPanel < Panel

      autoload :PanelApp, "rack/bug/panels/sql_panel/panel_app"
      autoload :QueryResult,    "rack/bug/panels/sql_panel/query"

      def initialize(app)
        super
        probe(self) do
          %w{ PostgreSQLAdapter MysqlAdapter SQLiteAdapter
            Mysql2Adapter OracleEnhancedAdapter }.each do |adapter|
            instrument "ActiveRecord::ConnectionAdapters::#{adapter}" do
              instance_probe :execute
            end
          end
        end
        table_setup("sql_queries")
        key_sql_template("")
      end

      def self.panel_mappings
        { "sql" => PanelApp.new }
      end

      def after_detect(method_call, timing, arguments, results)
        store(@env, QueryResult.new(arguments.first, timing.duration, method_call.backtrace, results))
      end

      def total_time(queries)
        (queries.inject(0) do |memo, query|
          memo + query.time
        end)
      end

      def name
        "sql"
      end

      def heading_for_request(number)
        queries = retrieve(number)
        "#{queries.size} Queries (%.2fms)" % total_time(queries)
      end

      def content_for_request(number)
        queries = retrieve(number)
        render_template "panels/sql", :queries => queries
      end

    end

  end
end
