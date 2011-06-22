require "ipaddr"
require "digest"
require "rack"
require "digest/sha1"
require "rack/bug/autoloading"
require 'rack/bug/logger'

class Rack::Bug
  include Options
  
  VERSION = "0.3.1"
  
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
    initialize_options options
    @app = asset_server(app)
    instance_eval(&block) if block_given?
    
    @logger = Logger.new(read_option(:log_level), read_option(:log_path))
    @toolbar = Toolbar.new(RedirectInterceptor.new(@app))
  end
  attr_reader :logger

  def call(env)
    env.replace @default_options.merge(env)
    @env = env
    @original_request = Rack::Request.new(@env)
    env['rack-bug.logger'] = @logger

    if toolbar_requested? && ip_authorized? && password_authorized? && toolbar_xhr?
      @toolbar.call(env)
    else
      @app.call(env)
    end
  end
  
private 

  def toolbar_xhr?
    !@original_request.xhr? || @original_request.path =~ /^\/__rack_bug__/
  end

  def asset_server(app)
    builder = Rack::Builder.new

    read_option(:panel_classes).each do |panel_class|
      begin
        middleware = panel_class.const_get("Middleware")
        puts "Using middleware for #{panel_class.name}"
        builder.use middleware
      rescue NameError
        #I guess no Middleware for you then.
      end
    end

    builder.run app
    app = builder.to_app
    static_app = Rack::Static.new(app, :urls => ["/__rack_bug__"], :root => public_path)
    return RackStaticBugAvoider.new(app, static_app)
  end

  def public_path
    ::File.expand_path(::File.dirname(__FILE__) + "/bug/public")
  end
  
  def toolbar_requested?
    @original_request.cookies["rack_bug_enabled"]
  end

  def ip_authorized?
    return true unless options["rack-bug.ip_masks"]

    logger.debug{ "Checking #{@original_request.ip} against ip_masks" }
    ip = IPAddr.new(@original_request.ip)

    mask = options["rack-bug.ip_masks"].find do |ip_mask|
      ip_mask.include?(ip)
    end
    if mask
      logger.debug{ "Matched #{mask}" }
      return true
    else
      logger.debug{ "Matched no masks" }
      return false
    end
  end

  def password_authorized?
    return true unless options["rack-bug.password"]

    logger.debug{"Checking password"}

    expected_sha = Digest::SHA1.hexdigest ["rack_bug", options["rack-bug.password"]].join(":")
    actual_sha = @original_request.cookies["rack_bug_password"]

    logger.debug{"Password result: #{actual_sha == expected_sha}"}
    actual_sha == expected_sha
  end
end
