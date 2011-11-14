require "erb"
require 'insight/database'
require 'insight/instrumentation'

module Insight

  # Panels are also Rack middleware
  class Panel
    include Render
    include ERB::Util
    include Database::RequestDataClient
    include Logging
    include Instrumentation::Client

    attr_reader :request

    def initialize(app)
      if panel_app
        #XXX use mappings
        @app = Rack::Cascade.new([panel_app, app])
      else
        @app = app
      end
    end

    def call(env)
      @env = env
      before(env)
      status, headers, body = @app.call(env)
      @request = Rack::Request.new(env)
      after(env, status, headers, body)
      env["insight.panels"] << self
      return [status, headers, body]
    end

    def panel_app
      nil
    end

    def self.panel_mappings
      {}
    end

    def has_content?
      true
    end

    def heading_for_request(number)
      heading rescue "xxx" #XXX: no panel should need this
    end

    def content_for_request(number)
      content rescue "" #XXX: no panel should need this
    end

    def before(env)
    end

    def after(env, status, headers, body)
    end

    def render(template)
    end

  end

end
