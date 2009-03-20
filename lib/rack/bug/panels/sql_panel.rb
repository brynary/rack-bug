require "digest"
require "active_support/secure_random"
require "rack/bug/extensions/sql_extension"

module Rack
  module Bug
    
    class SQLPanel < Panel
      
      class Query
        attr_reader :sql
        attr_reader :time
        
        def self.secret_key
          @secret_key ||= ActiveSupport::SecureRandom.hex
        end
        
        def initialize(sql, time)
          @sql = sql
          @time = time
        end
        
        def human_time
          "%.2fms" % (@time * 1_000)
        end

        def inspectable?
          sql.strip =~ /^SELECT /i
        end
        
        def with_profiling
          self.class.execute("SET PROFILING=1")
          result = yield
          self.class.execute("SET PROFILING=0")
          return result
        end
        
        def explain
          self.class.execute "EXPLAIN #{@sql}"
        end
        
        def profile
          with_profiling do
            execute
            self.class.execute <<-SQL
              SELECT *
                FROM information_schema.profiling
               WHERE query_id = (SELECT query_id FROM information_schema.profiling ORDER BY query_id DESC LIMIT 1)
            SQL
          end
        end
        
        def execute
          self.class.execute(@sql)
        end
        
        def valid_hash?(possible_hash)
          possible_hash == hash
        end
        
        def hash
          Digest::SHA1.hexdigest [self.class.secret_key, @sql].join(":")
        end
        
        def self.execute(sql)
          ActiveRecord::Base.connection.execute(sql)
        end
      end
      
      class PanelApp < Sinatra::Default
        include Rack::Bug::Render
        
        get "/__rack_bug__/explain_sql" do
          query = Query.new(params[:query], params[:time].to_f)
          raise "Security violation. Invalid query hash}" unless query.valid_hash?(params[:hash])
          render_template "panels/explain_sql", :result => query.explain, :query => query.sql, :time => query.time
        end
        
        get "/__rack_bug__/profile_sql" do
          query = Query.new(params[:query], params[:time].to_f)
          raise "Security violation. Invalid query hash" unless query.valid_hash?(params[:hash])
          render_template "panels/profile_sql", :result => query.profile, :query => query.sql, :time => query.time
        end
        
        get "/__rack_bug__/execute_sql" do
          query = Query.new(params[:query], params[:time].to_f)
          raise "Security violation. Invalid query hash" unless query.valid_hash?(params[:hash])
          render_template "panels/execute_sql", :result => query.execute, :query => query.sql, :time => query.time
        end
      end
      
      def panel_app
        PanelApp.new
      end
      
      def self.record(sql, &block)
        start_time = Time.now
        result = block.call
        queries << Query.new(sql, Time.now - start_time)
        
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