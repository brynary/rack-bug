require "rubygems"
require "webrat"
require "rack/test"

RAILS_ENV = "test"

#$LOAD_PATH.unshift File.dirname(File.dirname(__FILE__)) + '/lib'
#$LOAD_PATH.unshift File.dirname(File.dirname(__FILE__))

require "rack/insight"
require "fixtures/sample_app"
require "fixtures/dummy_panel"
require "rack/insight/rspec_matchers"

# Will use the default Ruby Logger.
Rack::Insight::Config.configure do |config|
  config[:verbosity] = Rack::Insight::Config::VERBOSITY[:silent]
  config[:log_level] = ::Logger::INFO
end
puts "Log Level for specs is #{::Logger::ERROR}"
puts "Verbosity level for specs is #{Rack::Insight::Config::VERBOSITY.select {|k,v| v == Rack::Insight::Config.verbosity }.keys.first.inspect} or #{Rack::Insight::Config.verbosity}"

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  # TODO: Turn this on.  Currently off because the specs bleed, and will randomly fail when run randomly.
  #config.order = 'random'

  TIME_MS_REGEXP = /\d+\.\d{2}ms/

  config.include Rack::Test::Methods
  config.include Webrat::Matchers
  config.include Rack::Insight::RspecMatchers

  config.before do
    @added_constants = []
  end

  config.after do
    @added_constants.each do |parent, added|
      parent.send :remove_const, added
    end
    @added_constants.clear
  end

  config.after :suite do
    # Clear the database between runs
    system(*%w{rm -f rack-insight.sqlite})
    Rack::Insight::Database.reset
  end

  def reset_insight(options=nil)
    app.prototype
    app.insight_app.reset(options)

    Rack::Insight.enable

    set_cookie "rack-insight_enabled=1"
  end

  def reset_config(config_options = {:panel_load_paths => [File::join('rack', 'insight', 'panels')]})
    Rack::Insight::Config.configure do |config|
      # spec folder is in the load path during specs!
      config[:panel_load_paths] = config_options[:panel_load_paths]
    end
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
    mock_constant(context)

    called_at = caller[0]
    file, line, real_method = called_at.split(":")
    called_at = [file,line,method].join(":")

    block ||= proc {}

    Rack::Insight::Instrumentation::Probe::ProbeRunner.probe_run(
      object, context, kind, args, called_at, method, &block)
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
