module Rack
  module Bug
    class CachePanel
      
      class Stats
        class Query
          attr_reader :method, :time, :hit, :keys
          
          def initialize(method, time, hit, keys)
            @method = method
            @time = time
            @hit = hit
            @keys = keys
          end
          
          def display_time
            "%.2fms" % time
          end
          
          def display_keys
            if keys.size == 1
              keys.first
            else
              keys.join(", ")
            end
          end
        end
        
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
        
        def display_time
          "%.2fms" % time
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
        
        def queries_to_param
          params = {}
          @queries.each_with_index do |query, index|
            params["keys_#{index}"] = query.keys.first
          end
          params
        end
      end
      
    end
  end
end