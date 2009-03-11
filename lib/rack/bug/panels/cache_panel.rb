require "rack/bug/extensions/memcache_extension"

module Rack
  module Bug
    
    class CachePanel < Panel
      
      class Stats
        Query = Struct.new(:method, :time, :hit, :keys)
        
        attr_reader :calls
        attr_reader :keys
        attr_reader :queries
        
        def initialize
          @queries = []
          @misses = 
          @calls = 0
          @time = 0.0
          @keys = []
        end
        
        def record_call(method, time, hit, *keys)
          @queries << Query.new(method, time, hit, keys)
          @calls += 1
          @time += time
          @keys += keys
        end
        
        def time
          @queries.inject(0) do |memo, query|
            memo + query.time
          end
        end
        
        def gets
          count_queries(:get)
        end
        
        def sets
          count_queries(:set)
        end
        
        def deletes
          count_queries(:delete)
        end
        
        def get_multis
          count_queries(:get_multi)
        end
        
        def hits
          @queries.select { |q| [:get, :get_multi].include?(q.method) && q.hit }.size
        end
        
        def misses
          @queries.select { |q| [:get, :get_multi].include?(q.method) && !q.hit }.size
        end
        
        def count_queries(method)
          @queries.select { |q| q.method == method }.size
        end
      end
      
      def self.record(method, *keys, &block)
        start_time = Time.now
        result = block.call
        total_time = Time.now - start_time
        hit = result.nil? ? false : true
        stats.record_call(method, total_time * 1_000, hit, *keys)
        return result
      end
      
      def self.reset
        Thread.current["rack.bug.cache"] = Stats.new
      end
      
      def self.stats
        Thread.current["rack.bug.cache"] ||= Stats.new
      end
      
      def name
        "cache"
      end
      
      def heading
        "Cache: %.2fms" % self.class.stats.time
      end

      def content
        @stats = self.class.stats
        @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/../views/panels/cache.html.erb")
        result = @template.result(binding)
        self.class.reset
        return result
      end
      
    end
    
  end
end