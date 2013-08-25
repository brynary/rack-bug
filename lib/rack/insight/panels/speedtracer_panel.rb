begin
  require 'yajl'
rescue LoadError
  #Means no Chrome Speedtracer...
end
require 'uuidtools'
require 'rack/insight/panels/speedtracer_panel/trace-app'
require 'rack/insight/panels/speedtracer_panel/tracer'

module Rack::Insight
  module SpeedTracer
    # TODO Refactor this class name...
    # TODO: Fix indentation of this class.
    # TODO: Update this class to Rack::Insight pattern.
    class Panel < ::Rack::Insight::Panel

    def initialize(app)
      @app = app
      @uuid = UUIDTools::UUID.random_create.to_s
      table_setup("speedtracer", "uuid")
      key_sql_template("'%s'")

      @tracer = Tracer.new(@table)
      probe(@tracer) do
        instrument("ActiveSupport::Notifications") do
          class_probe :instrument
        end

        instrument("ActionView::Rendering") do
          instance_probe :render
        end

        instrument("ActionView::Helpers::RecordTagHelper") do
          instance_probe :content_tag_for
        end

        instrument("ActionView::Partials::PartialRenderer") do
          instance_probe :render, :find_template, :render_collection, :collection_with_template, :collection_without_template, :partial_path, :collection_paths
        end

        instrument("ActionView::Template") do
          instance_probe :render, :compile
        end

        instrument("ActiveRecord::Base") do
          class_probe :find, :find_by_sql, :all, :first, :last, :count, :delete_all
          instance_probe :save, :save!, :destroy, :delete
        end

        instrument("ActionController::Base") do
          instance_probe :process, :render
        end
      end

      super
    end

    def call(env)
      env['rack-insight.speedtracer-id'] = @uuid

      status, headers, body = @app.call(env)
      store(env, env['rack-insight.speedtracer-id'], env['rack-insight.speedtracer-record'])
      headers['X-TraceUrl'] = '__insight__/speedtracer?id=' + env['rack-insight.speedtracer-id']
      return [status, headers, body]
    end

    def self.panel_mappings
      { "speedtracer" => TraceApp.new }
    end

    def heading
      "#{table_length} traces"
    end

    def content_for_request(request_id)
      trace = retrieve(request_id).first
      return "" if trace.nil?
      advice = []
      if not defined?(Yajl)
        advice << "yajl-ruby not installed - Speedtracer server events won't be available"
      end
      render_template "panels/speedtracer/traces", :trace => trace, :advice => advice
      end
    end
  end
end
