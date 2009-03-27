require "rack/bug/extensions/memcache_extension"

module Rack
  module Bug
    
    class CachePanel < Panel
      
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
          params = []
          @queries.each_with_index do |query, index|
            params << "keys[#{index}]=#{query.keys.first}"
          end
          params.join("&")
        end
      end
      
      class PanelApp
        include Rack::Bug::Render
        
        attr_reader :request
        
        def call(env)
          @request = Rack::Request.new(env)
          
          case request.path_info
          when "/__rack_bug__/view_cache"         then view_cache
          when "/__rack_bug__/delete_cache"       then delete_cache
          when "/__rack_bug__/delete_cache_list"  then delete_cache_list
          else
            not_found
          end
        end
        
        def params
          request.GET
        end
        
        def not_found
          [404, {}, []]
        end
        
        def ok
          Rack::Response.new(["OK"]).to_a
        end
        
        def render_template(*args)
          Rack::Response.new([super]).to_a
        end
        
        def view_cache
          render_template "panels/view_cache", :key => params["key"], :value => Rails.cache.read(params["key"])
        end
        
        def delete_cache
          raise "Rails not found... can't delete key" unless defined?(Rails)
          Rails.cache.delete(params["key"])
          ok
        end
        
        def delete_cache_list
          raise "Rails not found... can't delete key" unless defined?(Rails)
          params.each do |key, value|
            next unless key =~ /^keys/
            Rails.cache.delete(value)
          end
          ok
        end
      end
      
      def self.record(method, *keys, &block)
        return block.call unless Rack::Bug.enabled?
        
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
      
      def panel_app
        PanelApp.new
      end
      
      def name
        "cache"
      end
      
      def heading
        "Cache: %.2fms (#{self.class.stats.queries.size} calls)" % self.class.stats.time
      end

      def content
        result = render_template "panels/cache", :stats => self.class.stats
        self.class.reset
        return result
      end
      
    end
    
  end
end