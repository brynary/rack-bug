module Rack::Insight
  class EnableButton
    include Render

    MIME_TYPES = ["text/plain", "text/html", "application/xhtml+xml"]

    def initialize(app, insight)
      @app = app
      @insight = insight
    end

    def call(env)
      @env = env
      status, headers, body = @app.call(@env)

      response = Rack::Response.new(body, status, headers)

      inject_button(response) if okay_to_modify?(env, response)

      return response.to_a
    end

    def okay_to_modify?(env, response)
      return false unless response.ok?
      req = Rack::Request.new(env)
      filters = (env['rack-insight.path_filters'] || []).map { |str| %r(^#{str}) }
      filter = filters.find { |filter| env['REQUEST_PATH'] =~ filter }
      return MIME_TYPES.include?(req.media_type) && !req.xhr? && !filter
    end

    def inject_button(response)
      full_body = response.body.join
      full_body.sub! /<\/body>/, render + "</body>"

      response["Content-Length"] = full_body.bytesize.to_s

      response.body = [full_body]
    end

    def render
      render_template("enable-button")
    end
  end
end
