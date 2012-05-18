require "rack"
require "digest/sha1"
require "insight/filtered_backtrace"
require "insight/options"
require "insight/logger"
require "insight/panel"
require "insight/panel_app"
require "insight/params_signature"
require "insight/rack_static_bug_avoider"
require "insight/redirect_interceptor"
require "insight/render"
require "insight/toolbar"
require "insight/enable-button"
require "insight/path-filter"
require 'insight/logger'
require 'insight/request-recorder'
require 'insight/instrumentation/setup'
require 'insight/panels-content'
require 'insight/panels-header'

module Insight
  class App
    include Options
    INSIGHT_ROOT = "/__insight__"
    INSIGHT_REGEX = %r{^#{INSIGHT_ROOT}}

    VERSION = "0.4.4"

    class SecurityError < StandardError
    end

    def initialize(app, options = {}, &block)
      initialize_options options
      @base_app = app
      @panels = []
      instance_eval(&block) if block_given?

      @logger = Logger.new(read_option(:log_level), read_option(:log_path))
      Thread.current['insight.logger'] = @logger
      build_normal_stack
      build_debug_stack
      if options[:on_initialize]
        options[:on_initialize].call(self)
      end
    end
    attr_reader :logger
    attr_accessor :panels

    def call(env)
      @original_request = Rack::Request.new(env)
      if insight_active?
        @env = env
        self.options = @default_options

        env['insight.logger'] = @logger
        Thread.current['insight.logger'] = @logger

        Insight.enable
        env["insight.panels"] = []
        @debug_stack.call(env)
      else
        @normal_stack.call(env)
      end
    end


    def reset(new_options=nil)
      @env = nil
      initialize_options(new_options)

      Insight::Instrumentation::ClassProbe::all_probes.each do |probe|
        probe.clear_collectors
      end
      Insight::Instrumentation::InstanceProbe::all_probes.each do |probe|
        probe.clear_collectors
      end
      Insight::Instrumentation::PackageDefinition.clear_collectors

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
      @original_request.cookies["insight_enabled"]
    end

    def ip_authorized?
      return true unless options["insight.ip_masks"]

      logger.debug{ "Checking #{@original_request.ip} against ip_masks" }
      ip = IPAddr.new(@original_request.ip)

      mask = options["insight.ip_masks"].find do |ip_mask|
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
      return true unless options["insight.password"]

      logger.debug{"Checking password"}

      expected_sha = Digest::SHA1.hexdigest ["insight", options["insight.password"]].join(":")
      actual_sha = @original_request.cookies["insight_password"]

      logger.debug{"Password result: #{actual_sha == expected_sha}"}
      actual_sha == expected_sha
    end
  end
end
