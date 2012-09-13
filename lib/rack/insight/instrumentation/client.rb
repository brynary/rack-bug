require 'rack/insight/instrumentation/package-definition'
module Rack::Insight::Instrumentation
  module Client
    def probe(collector, &block)
      collector.class.is_probing = true
      ::Rack::Insight::Instrumentation::PackageDefinition::probe(collector, &block)
    end

    def request_start(env, start)
    end

    def before_detect(method_call, arguments)
    end

    def after_detect(method_call, timing, arguments, result)
    end

    def request_finish(env, status, headers, body, timing)
    end
  end
end
