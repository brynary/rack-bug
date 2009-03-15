require "rack"

module Rack::Bug
  require "rack/bug/middleware"
  
  VERSION = "0.1.0"
  
  def self.new(*args, &block)
    Middleware.new(*args, &block)
  end
end