require 'rack'
require "digest/sha1"
require "rack/insight/logging"
require "rack/insight/config"
require "rack/insight/filtered_backtrace"
require "rack/insight/options"
require 'rack/insight/magic_insight'
require 'rack/insight/default_invocation'
require "rack/insight/panel"
require "rack/insight/panel_app"
require "rack/insight/params_signature"
require "rack/insight/rack_static_bug_avoider"
require "rack/insight/redirect_interceptor"
require "rack/insight/render"
require "rack/insight/toolbar"
require "rack/insight/enable-button"
require "rack/insight/path-filter"
require 'rack/insight/request-recorder'
require 'rack/insight/instrumentation/setup'
require 'rack/insight/panels-content'
require 'rack/insight/panels-header'

module Rack::Insight
  class App
    include Rack::Insight::Options
    include Rack::Insight::Logging

    INSIGHT_ROOT = "/__insight__"
    INSIGHT_REGEX = %r{^#{INSIGHT_ROOT}}

    class SecurityError < StandardError
    end

    def initialize(app, options = {}, &block)
      initialize_options options
      @base_app = app
      @panels = []
      instance_eval(&block) if block_given?
      build_normal_stack
      build_debug_stack
      # TODO: Understand when this would be used
      if options[:on_initialize]
        options[:on_initialize].call(self)
      end
    end
    attr_accessor :panels

    # allow access to configuration settings directly through the app object!
    def config
      Rack::Insight::Config.config
    end

    def call(env)
      @original_request = Rack::Request.new(env)
      @env = env
      self.options = @default_options
      if insight_active?
        Rack::Insight.enable
        env["rack-insight.panels"] = []
        @debug_stack.call(env)
      else
        @normal_stack.call(env)
      end
    end

    def reset(new_options=nil)
      @env = nil
      initialize_options(new_options)

      Rack::Insight::Instrumentation::ClassProbe::all_probes.each do |probe|
        probe.clear_collectors
      end
      Rack::Insight::Instrumentation::InstanceProbe::all_probes.each do |probe|
        probe.clear_collectors
      end
      Rack::Insight::Instrumentation::PackageDefinition.clear_collectors

      build_debug_stack
    end

    private

    def insight_active?
      return (toolbar_requested? && ip_authorized? && password_authorized?)
    end

    def build_normal_stack
      builder = Rack::Builder.new
      builder.use EnableButton, self
      builder.run Rack::Cascade.new([ asset_mapped(Rack::Builder.new), @base_app ])
      @normal_stack = builder.to_app
    end

    def build_debug_stack
      @panels.clear
      builder = Rack::Builder.new
      builder.use Toolbar, self
      builder.run Rack::Cascade.new([panel_mappings, shortcut_stack(@base_app), collection_stack(@base_app)])

      @debug_stack = builder.to_app
    end

    def panel_mappings
      classes = read_option(:panel_classes)
      root = INSIGHT_ROOT
      insight = self
      builder = Rack::Builder.new do
        classes.each do |panel_class|
          panel_class.panel_mappings.each do |path, app|
            map [root, path].join("/") do
              run app
            end
          end
        end
        map root + "/panels_content" do
          run PanelsContent.new(insight)
        end
        map root + "/panels_header" do
          run PanelsHeader.new(insight)
        end
      end
      return asset_mapped(builder)
    end

    def shortcut_stack(app)
      Rack::Builder.app do
        use PathFilter
        run app
      end
    end

    def collection_stack(app)
      classes = read_option(:panel_classes)
      insight_id = self.object_id
      panels = self.panels

      #Builder makes it impossible to access the panels

      app = Instrumentation::Setup.new(app)
      app = RedirectInterceptor.new(app)
      #Reversed?  Does it matter?
      app = classes.inject(app) do |app, panel_class|
        panel = panel_class.new(app)
        panels << panel
        panel
      end
      app = RequestRecorder.new(app)
      return app
    end

    def asset_mapped(builder)
      path = public_path
      builder.map INSIGHT_ROOT do
        run Rack::File.new(path)
      end
      builder.to_app
    end

    def public_path
      ::File.expand_path("../../insight/public/__insight__", __FILE__)
    end

    def toolbar_requested?
      @original_request.cookies["rack-insight_enabled"]
    end

    def ip_authorized?
      return true unless options["rack-insight.ip_masks"]

      logger.info{ "Checking #{@original_request.ip} against ip_masks" } if verbose(:high)
      ip = IPAddr.new(@original_request.ip)

      mask = options["rack-insight.ip_masks"].find do |ip_mask|
        ip_mask.include?(ip)
      end
      if mask
        logger.info{ "Matched #{mask}" } if verbose(:high)
        return true
      else
        logger.info{ "Matched no masks" } if verbose(:high)
        return false
      end
    end

    def password_authorized?
      return true unless options["rack-insight.password"]

      logger.info{"Checking password"} if verbose(:low)

      expected_sha = Digest::SHA1.hexdigest ["rack-insight", options["rack-insight.password"]].join(":")
      actual_sha = @original_request.cookies["rack-insight_password"]

      logger.info{"Password result: #{actual_sha == expected_sha}"} if verbose(:med)
      actual_sha == expected_sha
    end
  end
end
