require "rubygems"

unless $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__) + "/.."))
  $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/.."))
end

require "rack/bug/middleware"

module Rack
  module Bug
    
    VERSION = "0.1.0"
    
    def self.new(*args, &block)
      Middleware.new(*args, &block)
    end
    
  end
end