require 'rack/insight/database'

module Rack::Insight
  class RequestRecorder
    def initialize(app)
      @app = app
      @request_table = Database::RequestTable.new()
    end

    def call(env)
      env["rack-insight.request-id"] =
        @request_table.store(env["REQUEST_METHOD"],
                             env["PATH_INFO"])

      results = @app.call(env)

      @request_table.sweep

      return results
    end
  end
end
