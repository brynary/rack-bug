module Insight
  class EnableButton
    include Render

    MIME_TYPES = ["text/html", "application/xhtml+xml"]

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
      req = Rack::Request.new(env)
      content_type, charset = response.content_type.split(";")

      response.ok? && MIME_TYPES.include?(content_type) && !req.xhr?
    end

    def inject_button(response)
      full_body = response.body.join
      full_body.sub! /<\/body>/, render + "</body>"

      response["Content-Length"] = full_body.size.to_s

      response.body = [full_body]
    end

    def render
      render_template("enable-button")
    end
  end
end
