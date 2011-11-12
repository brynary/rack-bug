module Insight::Instrumentation
  class InstrumentSetup
    def initialize(app)
      @app = app
    end

    def setup(env)
      instrument = Instrument.new

      PackageDefinition.start
      instrument.start(env)

      env["insight.instrument"] = instrument
      Thread::current["insight.instrument"] = instrument
    end

    def teardown(env, status, headers, body)
      instrument, env["insight.instrument"] = env["insight.instrument"], nil
      instrument.finish(env, status, headers, body)
      Thread::current["insight.instrument"] = nil

      env["insight.duration"] = instrument.duration
    end

    def call(env)
      setup(env)
      status, headers, body = @app.call(env)
      teardown(env, status, headers, body)
      return [status, headers, body]
    end
  end
end
