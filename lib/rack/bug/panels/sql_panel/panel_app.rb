module Rack
  module Bug
    class SQLPanel
      
      class PanelApp < ::Rack::Bug::PanelApp
  
        def dispatch
          case request.path_info
          when "/__rack_bug__/explain_sql" then explain_sql
          when "/__rack_bug__/profile_sql" then profile_sql
          when "/__rack_bug__/execute_sql" then execute_sql
          else not_found
          end
        end
        
        def explain_sql
          validate_params
          query = Query.new(params["query"], params["time"].to_f)
          render_template "panels/explain_sql", :result => query.explain, :query => query.sql, :time => query.time
        end
  
        def profile_sql
          validate_params
          query = Query.new(params["query"], params["time"].to_f)
          render_template "panels/profile_sql", :result => query.profile, :query => query.sql, :time => query.time
        end
  
        def execute_sql
          validate_params
          query = Query.new(params["query"], params["time"].to_f)
          render_template "panels/execute_sql", :result => query.execute, :query => query.sql, :time => query.time
        end
        
      end
    end
  end
end