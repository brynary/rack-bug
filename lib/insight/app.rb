require "rack"
require "digest/sha1"
require "insight/autoloading"
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

    VERSION = "0.3.1"

    class SecurityError < StandardError
    end
    def initialize(app, options = {}, &block)
      initialize_options options
      @base_app = app
      @app = asset_server(@base_app)
      @panels = []
      instance_eval(&block) if block_given?

      @logger = Logger.new(read_option(:log_level), read_option(:log_path))
      Thread.current['insight.logger'] = @logger
      build_debug_stack
      if options[:on_initialize]
        options[:on_initialize].call(self)
      end
    end
    attr_reader :logger
    attr_accessor :panels

    def call(env)
      env.replace @default_options.merge(env)
      @env = env
      @original_request = Rack::Request.new(@env)
      env['insight.logger'] = @logger

      if insight_active?
        Insight.enable
        env["insight.panels"] = []
        result = @debug_stack.call(env)
        result
      else
        @app.call(env)
      end
    end


    def reset(new_options=nil)
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

    def build_debug_stack
      @panels.clear
      builder = Rack::Builder.new
      builder.use Toolbar, self
      builder.run Rack::Cascade.new([panel_mappings, collection_stack(@base_app)])
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


    def collection_stack(app)
      classes = read_option(:panel_classes)
      insight_id = self.object_id
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
        use Instrumentation::Setup
        run app
      end
    end

    def asset_mapped(builder)
      path = public_path
      builder.map INSIGHT_ROOT do
        run Rack::File.new(path)
      end
      builder.to_app
    end

    def asset_server(app)
      Rack::Cascade.new [ asset_mapped(Rack::Builder.new), app ]
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
