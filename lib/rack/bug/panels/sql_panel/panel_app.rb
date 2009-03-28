require "rack/bug/panel_app"

module Rack
  module Bug
    class SQLPanel
      
      class PanelApp < ::Rack::Bug::PanelApp
  
        def dispatch
          return not_found if secret_key.nil? || secret_key == ""
    
          case request.path_info
          when "/__rack_bug__/explain_sql" then explain_sql
          when "/__rack_bug__/profile_sql" then profile_sql
          when "/__rack_bug__/execute_sql" then execute_sql
          else not_found
          end
        end
  
        def secret_key
          @request.env['rack-bug.secret_key']
        end
  
        def validate_query_hash(query)
          raise SecurityError.new("Invalid query hash") unless query.valid_hash?(secret_key, params["hash"])
        end
  
        def explain_sql
          query = Query.new(params["query"], params["time"].to_f)
          validate_query_hash(query)
          render_template "panels/explain_sql", :result => query.explain, :query => query.sql, :time => query.time
        end
  
        def profile_sql
          query = Query.new(params["query"], params["time"].to_f)
          validate_query_hash(query)
          render_template "panels/profile_sql", :result => query.profile, :query => query.sql, :time => query.time
        end
  
        def execute_sql
          query = Query.new(params["query"], params["time"].to_f)
          validate_query_hash(query)
          render_template "panels/execute_sql", :result => query.execute, :query => query.sql, :time => query.time
        end
        
      end
    end
  end
end