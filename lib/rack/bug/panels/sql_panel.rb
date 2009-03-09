require "rack/bug/extensions/activerecord_extension"

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
      
      def self.record(sql, time)
        Thread.current["queries"] ||= []
        Thread.current["queries"] << Query.new(sql, time)
      end
      
      def self.reset
        Thread.current["queries"] = []
      end
      
      def self.queries
        Thread.current["queries"] || []
      end
      
      def name
        "sql"
      end
      
      def heading
        "#{self.class.queries.size} SQL Queries"
      end

      def content
        @queries = self.class.queries
        @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/../views/panels/sql.html.erb")
        result = @template.result(binding)
        self.class.reset
        return result
      end
      
    end
    
  end
end