require "rubygems"
require "webrat"
require "rack/test"

RAILS_ENV = "test"

$LOAD_PATH.unshift File.dirname(File.dirname(__FILE__)) + '/lib'
$LOAD_PATH.unshift File.dirname(File.dirname(__FILE__))

require "insight"
require "spec/fixtures/sample_app"
require "spec/fixtures/dummy_panel"
require "spec/custom_matchers"

RSpec.configure do |config|
  TIME_MS_REGEXP = /\d+\.\d{2}ms/

    config.include Rack::Test::Methods
  config.include Webrat::Matchers
  config.include CustomMatchers

  config.before do
    app.prototype
    @added_constants = []
  end

  config.after do
    @added_constants.each do |parent, added|
      parent.send :remove_const, added
    end
    @added_constants.clear
  end

  def reset_insight
    system(*%w{rm -f insight.sqlite})
    Insight.enable

    Insight::Database.reset

    Insight::Instrumentation::ClassProbe::all_probes.each do |probe|
      probe.clear_collectors
    end
    Insight::Instrumentation::InstanceProbe::all_probes.each do |probe|
      probe.clear_collectors
    end
    Insight::Instrumentation::PackageDefinition.clear_collectors


    if app.insight_app.nil?
    else
      app.insight_app.instance_eval do
        build_debug_stack
      end
    end

    set_cookie "insight_enabled=1"
  end

  def app
    SampleApp
  end

  def mock_constant(name)
    parts = name.split("::")
    klass = parts.pop
    mod = parts.inject(Object) do |const, part|
      begin
        const.const_get(part)
      rescue NameError
        @added_constants << [const, part]
        mod = Module.new
        const.const_set(part.to_sym, mod)
        mod
      end
    end
    begin
      mod.const_get(klass)
    rescue NameError
      mod.const_set(klass, Class.new)
    end
  end

  def mock_method_call(context, method, args=[], kind=:instance, object=Object.new, &block)
    called_at = caller[0]
    file, line, real_method = called_at.split(":")
    called_at = [file,line,method].join(":")

    block ||= proc {}

    Insight::Instrumentation::Probe::ProbeRunner.probe_run(
      object, context, kind, args, called_at, &block)
  end

  def rack_env(key, value)
    @rack_env ||= {}
    @rack_env[key] = value
  end

  def get_via_rack(uri, params = {}, env = {}, &block)
    env = env.merge(@rack_env) if @rack_env
    get(uri, params, env, &block)
  end
end
