require "ipaddr"
require "digest"
require "rack"
require "digest/sha1"
require "rack/bug/autoloading"
require 'rack/bug/logger'
require 'rack/bug/request-recorder'
require 'rack/bug/instrument-setup'
require 'rack/bug/panels-content'
require 'rack/bug/panels-header'

class Rack::Bug
  include Options
  RACK_BUG_ROOT = "/__rack_bug__"
  RACK_BUG_REGEX = %r{^#{RACK_BUG_ROOT}}

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
    @panels = []
    instance_eval(&block) if block_given?

    @logger = Logger.new(read_option(:log_level), read_option(:log_path))
    @bug_app = make_bug_app(app)
  end
  attr_reader :logger
  attr_accessor :panels

  def call(env)
    env.replace @default_options.merge(env)
    @env = env
    @original_request = Rack::Request.new(@env)
    env['rack-bug.logger'] = @logger

    if rack_bug_active?
      Rack::Bug.enable
      env["rack-bug.panels"] = []
      result = @bug_app.call(env)
      Rack::Bug.disable
      result
    else
      @app.call(env)
    end
  end

  private

  def rack_bug_active?
    return (toolbar_requested? && ip_authorized? && password_authorized?)
  end

  def make_bug_app(app)
    builder = Rack::Builder.new
    builder.use Toolbar, self
    builder.run Rack::Cascade.new([panel_mappings, collection_stack(app)])
    builder.to_app
  end

  def panel_mappings
    classes = read_option(:panel_classes)
    root = RACK_BUG_ROOT
    bug = self
    builder = Rack::Builder.new do
      classes.each do |panel_class|
        panel_class.panel_mappings.each do |path, app|
          map [root, path].join("/") do
            run app
          end
        end
      end
      map root + "/panels_content" do
        run PanelsContent.new(bug)
      end
      map root + "/panels_header" do
        run PanelsHeader.new(bug)
      end
    end
    return asset_mapped(builder)
  end


  def collection_stack(app)
    classes = read_option(:panel_classes)
    panels = self.panels
    Rack::Builder.app do
      use RequestRecorder
      classes.each do |panel_class|
        run(lambda do |app|
          panel = panel_class.new(app)
          panels << panel
          panel
        end)
      end
      use RedirectInterceptor
      use InstrumentSetup
      run app
    end
  end

  def asset_mapped(builder)
    path = public_path
    builder.map RACK_BUG_ROOT do
      run Rack::File.new(path)
    end
    builder.to_app
  end

  def asset_server(app)
    Rack::Cascade.new [ asset_mapped(Rack::Builder.new), app ]
  end

  def public_path
    ::File.expand_path(::File.dirname(__FILE__) + "/bug/public/__rack_bug__")
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
