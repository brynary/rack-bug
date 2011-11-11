class InstrumentSetup
  def initialize(app)
    @app = app
  end

  def call(env)
    instrument = Instrumentation::Instrument.new

    Instrumentation::PackageDefinition.start
    instrument.start(env)

    env["insight.instrument"] = instrument
    Thread::current["insight.instrument"] = instrument

    status, headers, body = @app.call(env)

    instrument.finish(env, status, headers, body)

    env["insight.instrument"] = nil
    Thread::current["insight.instrument"] = nil

    env["insight.duration"] = instrument.duration

    return [status, headers, body]
  end
end
