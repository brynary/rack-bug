require "rack/bug/extensions/activerecord_extension"

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
        "#{self.class.queries.size} SQL Queries (%.2fms)" % self.class.total_time
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