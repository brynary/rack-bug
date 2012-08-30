module Rack::Insight::Instrumentation
  class Setup
    def initialize(app)
      @app = app
    end

    def setup(env)
      instrument = Instrument.new

      PackageDefinition.start
      instrument.start(env)

      env["rack-insight.instrument"] = instrument
      Thread::current["rack-insight.instrument"] = instrument
    end

    def teardown(env, status, headers, body)
      instrument, env["rack-insight.instrument"] = env["rack-insight.instrument"], nil
      instrument.finish(env, status, headers, body)
      Thread::current["rack-insight.instrument"] = nil

      env["rack-insight.duration"] = instrument.duration
    end

    def call(env)
      setup(env)
      status, headers, body = @app.call(env)
      teardown(env, status, headers, body)
      return [status, headers, body]
    end
  end
end
