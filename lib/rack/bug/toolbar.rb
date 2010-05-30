module Rack
  class Bug
    class Toolbar
      include Render

      MIME_TYPES = ["text/html", "application/xhtml+xml"]

      def initialize(app)
        @app = app
      end
      
      def call(env)
        @env = env
        @env["rack-bug.panels"] = []

        Rack::Bug.enable
        status, headers, body = builder.call(@env)
        Rack::Bug.disable

        @response = Rack::Response.new(body, status, headers)

        intercept_redirect if intercept_redirect?
        inject_toolbar if modify?

        return @response.to_a
      end

      def intercept_redirect
        redirect_to = @response.location
        new_body = render_template("redirect", :redirect_to => @response.location)
        new_response = Rack::Response.new(new_body, 200, { "Content-Type" => "text/html" })
        new_response["Content-Length"] = new_body.size.to_s
        @response = new_response
      end

      def intercept_redirect?
        @response.redirect? && @env["rack-bug.intercept_redirects"]
      end

      def modify?
        @response.ok? &&
        @env["HTTP_X_REQUESTED_WITH"] != "XMLHttpRequest" &&
        MIME_TYPES.include?(@response.content_type.split(";").first)
      end

      def builder
        builder = Rack::Builder.new

        @env["rack-bug.panel_classes"].each do |panel_class|
          builder.use panel_class
        end

        builder.run @app

        return builder
      end

      def inject_toolbar
        full_body = @response.body.join
        full_body.sub! /<\/body>/, render + "</body>"

        @response["Content-Length"] = full_body.size.to_s

        # Ensure that browser does
        @response["Etag"] = ""
        @response["Cache-Control"] = "no-cache"

        @response.body = [full_body]
      end

      def render
        render_template("toolbar", :panels => @env["rack-bug.panels"].reverse)
      end

    end

  end
end
