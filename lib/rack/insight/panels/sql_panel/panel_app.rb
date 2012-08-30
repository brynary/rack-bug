require 'rack/insight/panels/sql_panel/query'

module Rack::Insight
  class SQLPanel

    class PanelApp < ::Rack::Insight::PanelApp

      def dispatch
        case request.path_info
        when "/explain" then explain_sql
        when "/profile" then profile_sql
        when "/execute" then execute_sql
        else not_found
        end
      end

      def explain_sql
        validate_params
        query = ExplainResult.new(params["query"], params["time"].to_f)
        render_template "panels/explain_sql", :query => query
      end

      def profile_sql
        validate_params
        query = ProfileResult.new(params["query"], params["time"].to_f)
        render_template "panels/profile_sql", :query => query
      end

      def execute_sql
        validate_params
        query = QueryResult.new(params["query"], params["time"].to_f)
        render_template "panels/execute_sql", :query => query
      end

    end
  end
end
