require "rubygems"
require "spec"
require "webrat"
require "rack/test"

RAILS_ENV = "test"

$LOAD_PATH.unshift File.dirname(File.dirname(__FILE__)) + '/lib'
$LOAD_PATH.unshift File.dirname(File.dirname(__FILE__))

require "rack/bug"
require "spec/fixtures/sample_app"
require "spec/fixtures/dummy_panel"
require "spec/custom_matchers"

Spec::Runner.configure do |config|
  TIME_MS_REGEXP = /\d+\.\d{2}ms/

  config.include Rack::Test::Methods
  config.include Webrat::Matchers
  config.include CustomMatchers

  config.before do
    # This allows specs to record data outside the request
    Rack::Bug.enable

    # Set the cookie that triggers Rack::Bug under normal conditions
    set_cookie "rack_bug_enabled=1"
  end

  def app
    SampleApp
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
