if defined?(ActiveRecord)
  ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
    def log_with_rack_bug(sql, name, &block)
      start_time = Time.now
      result = log_without_rack_bug(sql, name, &block)
      Rack::Bug::SQLPanel.record_query(sql, Time.now - start_time)
      return result
    end
    
    alias_method_chain :log, :rack_bug
  end
end

module Rack
  module Bug
    
    class SQLPanel < Panel
      
      class Query
        attr_reader :sql
        
        def initialize(sql, time)
          @sql = sql
          @time = time
        end
        
        def time
          "%.1fms" % (@time * 1_000)
        end
      end
      
      def self.record_query(sql, time)
        Thread.current["queries"] ||= []
        Thread.current["queries"] << Query.new(sql, time)
      end
      
      def self.reset_queries
        Thread.current["queries"] = []
      end
      
      def self.queries
        Thread.current["queries"] || []
      end
      
      def name
        "sql"
      end
      
      def heading
        "SQL"
      end

      def content
        @queries = self.class.queries
        @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/../views/panels/sql.html.erb")
        result = @template.result(binding)
        self.class.reset_queries
        return result
      end
      
    end
    
  end
end