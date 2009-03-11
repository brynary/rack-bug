require "sinatra/base"

module Rack
  module Bug
    
    class App < Sinatra::Default
      
      get "/__rack_bug__/delete_cache" do
        if defined?(Rails)
          sleep 2
          Rails.cache.delete(params[:key])
          "OK"
        else
          raise "Rails not found... can't delete key"
        end
      end
      
    end
    
  end
end