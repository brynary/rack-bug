require "ipaddr"
require "digest"
require "rack"
require "digest/sha1"
require "rack/bug/autoloading"

class Rack::Bug
  include Options
  
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

  def initialize(app, options = {}, &block)
    @app = asset_server(app)
    initialize_options options
    instance_eval(&block) if block_given?
    
    @toolbar = Toolbar.new(RedirectInterceptor.new(@app))
  end


  def call(env)
    env.replace @default_options.merge(env)
    @env = env
    @original_request = Rack::Request.new(@env)

    if toolbar_requested? && ip_authorized? && password_authorized? && !@original_request.xhr?
      @toolbar.call(env)
    else
      @app.call(env)
    end
  end
  
private 

  def asset_server(app)
    RackStaticBugAvoider.new(app, Rack::Static.new(app, :urls => ["/__rack_bug__"], :root => public_path))
  end

  def public_path
    ::File.expand_path(::File.dirname(__FILE__) + "/bug/public")
  end
  
  def toolbar_requested?
    @original_request.cookies["rack_bug_enabled"]
  end

  def ip_authorized?
    return true unless options["rack-bug.ip_masks"]

    options["rack-bug.ip_masks"].any? do |ip_mask|
      ip_mask.include?(IPAddr.new(@original_request.ip))
    end
  end

  def password_authorized?
    return true unless options["rack-bug.password"]

    expected_sha = Digest::SHA1.hexdigest ["rack_bug", options["rack-bug.password"]].join(":")
    actual_sha = @original_request.cookies["rack_bug_password"]

    actual_sha == expected_sha
  end
  
end
