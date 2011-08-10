module Rack
  class Bug
    class Toolbar
      include Render

      MIME_TYPES = ["text/html", "application/xhtml+xml"]

      def initialize(app, bug)
        @app = app
        @bug = bug
        @request_table = Database::RequestTable.new
      end

      def call(env)
        @env = env
        status, headers, body = @app.call(@env)

        response = Rack::Response.new(body, status, headers)

        inject_toolbar(response) if okay_to_modify?(env, response)

        return response.to_a
      end

      def okay_to_modify?(env, response)
        req = Rack::Request.new(env)
        content_type, charset = response.content_type.split(";")

        response.ok? && MIME_TYPES.include?(content_type) && !req.xhr?
      end

      def inject_toolbar(response)
        full_body = response.body.join
        full_body.sub! /<\/body>/, render + "</body>"

        response["Content-Length"] = full_body.size.to_s

        # Ensure that browser doesn't cache
        response["Etag"] = ""
        response["Cache-Control"] = "no-cache"

        response.body = [full_body]
      end

      def render
        req_id = (@env['rack-bug.request-id'] || @request_table.last_request_id).to_i
        requests = @request_table.to_a.map do |row|
          { :id => row[0], :method => row[1], :path => row[2] }
        end
        headers_fragment = render_template("headers_fragment",
                                           :panels => @bug.panels,
                                           :request_id => req_id)

        current_request_fragment = render_template("request_fragment",
                                                   :request_id => req_id,
                                                   :requests => requests,
                                                   :panels => @bug.panels)
        render_template("toolbar",
                        :request_fragment => current_request_fragment,
                        :headers_fragment => headers_fragment,
                        :request_id => req_id)
      end
    end
  end
end
