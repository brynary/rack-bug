require "rack"
require "digest/sha1"
require "rack/bug/autoloading"

class Rack::Bug
  VERSION = "0.3.0"

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
  
  def initialize(*args, &block)
    @toolbar = Toolbar.new(*args, &block)
  end

  def call(env)
    @toolbar.call(env)
  end
  
end
