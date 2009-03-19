require "rack/bug/extensions/sql_extension"

module Rack
  module Bug
    
    class SQLPanel < Panel
      
      class Query
        attr_reader :sql
        attr_reader :time
        
        def initialize(sql, time)
          @sql = sql
          @time = time
        end
        
        def human_time
          "%.2fms" % (@time * 1_000)
        end

        def inspectable?
          sql.strip !~ /^SHOW FIELDS/i &&
          sql.strip !~ /^SET /i
        end
      end
      
      class PanelApp < Sinatra::Default
        include Rack::Bug::Render
        
        get "/__rack_bug__/explain_sql" do
          result = ActiveRecord::Base.connection.execute("EXPLAIN #{params[:query]}")
          render_template "panels/explain_sql", :result => result, :query => params[:query], :time => params[:time].to_f
        end
        
        get "/__rack_bug__/profile_sql" do
          ActiveRecord::Base.connection.execute("SET PROFILING=1")
          ActiveRecord::Base.connection.execute(params[:query])
          result = ActiveRecord::Base.connection.execute("SELECT * FROM information_schema.profiling WHERE query_id=(SELECT query_id FROM information_schema.profiling ORDER BY query_id DESC LIMIT 1)")
          ActiveRecord::Base.connection.execute("SET PROFILING=0")
          render_template "panels/profile_sql", :result => result, :query => params[:query], :time => params[:time].to_f
        end
        
        get "/__rack_bug__/execute_sql" do
          result = ActiveRecord::Base.connection.execute(params[:query])
          render_template "panels/execute_sql", :result => result, :query => params[:query], :time => params[:time].to_f
        end
      end
      
      def panel_app
        PanelApp.new
      end
      
      def self.record(sql, &block)
        start_time = Time.now
        result = block.call
        
        Thread.current["rack.test.queries"] ||= []
        Thread.current["rack.test.queries"] << Query.new(sql, Time.now - start_time)
        
        return result
      end
      
      def self.reset
        Thread.current["rack.test.queries"] = []
      end
      
      def self.queries
        Thread.current["rack.test.queries"] || []
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