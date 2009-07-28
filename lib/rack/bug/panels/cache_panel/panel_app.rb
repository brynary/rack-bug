module Rack
  module Bug
    class CachePanel
      
      class PanelApp < ::Rack::Bug::PanelApp
        
        def dispatch
          case request.path_info
          when "/__rack_bug__/view_cache"         then view_cache
          when "/__rack_bug__/delete_cache"       then delete_cache
          when "/__rack_bug__/delete_cache_list"  then delete_cache_list
          else not_found
          end
        end
        
        def ok
          Rack::Response.new(["OK"]).to_a
        end
        
        def view_cache
          validate_params
          render_template "panels/view_cache", :key => params["key"], :value => Rails.cache.read(params["key"])
        end
        
        def delete_cache
          validate_params
          raise "Rails not found... can't delete key" unless defined?(Rails)
          Rails.cache.delete(params["key"])
          ok
        end
        
        def delete_cache_list
          validate_params
          raise "Rails not found... can't delete key" unless defined?(Rails)
          
          params.each do |key, value|
            next unless key =~ /^keys_/
            Rails.cache.delete(value)
          end
          
          ok
        end
        
      end
      
    end
  end
end