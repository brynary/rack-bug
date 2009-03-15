require "rack"

module Rack::Bug
  require "rack/bug/toolbar"
  
  VERSION = "0.1.0"
  
  def self.new(*args, &block)
    Toolbar.new(*args, &block)
  end
end