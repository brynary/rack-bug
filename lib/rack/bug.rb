require "rack"

module Rack::Bug
  require "rack/bug/toolbar"
  
  VERSION = "0.1.0"
  
  class SecurityError < StandardError
  end
  
  def self.enable
    Thread.current["rack-bug.enabled"] = true
  end
  
  def self.disable
    Thread.current["rack-bug.enabled"] = false
  end
  
  def self.enabled?
    Thread.current["rack-bug.enabled"] == true
  end
  
  def self.new(*args, &block)
    Toolbar.new(*args, &block)
  end
end