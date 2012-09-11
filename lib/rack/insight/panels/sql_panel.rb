require "digest"

module Rack::Insight

  class SQLPanel < Panel

    require "rack/insight/panels/sql_panel/panel_app"
    require "rack/insight/panels/sql_panel/query"

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
