module Rack
  module Bug
    class CachePanel
      
      class PanelApp
        include Rack::Bug::Render
        
        attr_reader :request
        
        def call(env)
          @request = Rack::Request.new(env)
          dispatch
        end
        
        def dispatch
          case request.path_info
          when "/__rack_bug__/view_cache"         then view_cache
          when "/__rack_bug__/delete_cache"       then delete_cache
          when "/__rack_bug__/delete_cache_list"  then delete_cache_list
          else not_found
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
      
    end
  end
end