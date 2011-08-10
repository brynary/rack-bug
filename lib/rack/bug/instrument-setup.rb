require 'rack/bug/instrumentation'

class Rack::Bug
  class InstrumentSetup
    def initialize(app)
      @app = app
    end

    def call(env)
      instrument = Instrumentation::Instrument.new

      instrument.start(env)

      env["rack-bug.instrument"] = instrument
      Thread::current["rack-bug.instrument"] = instrument

      status, headers, body = @app.call(env)

      instrument.finish(env, status, headers, body)

      env["rack-bug.instrument"] = nil
      Thread::current["rack-bug.instrument"] = nil

      env["rack-bug.duration"] = instrument.duration

      return [status, headers, body]
    end
  end
end
