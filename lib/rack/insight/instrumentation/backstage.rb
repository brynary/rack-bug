module Rack::Insight::Instrumentation
  module Backstage
    def backstage
      Thread.current["instrumented_backstage"] = true
      yield
    ensure
      Thread.current["instrumented_backstage"] = false
    end
  end
end
