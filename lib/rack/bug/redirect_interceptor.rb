module Rack
  class Bug    
    class RedirectInterceptor
      include Render
      
      def initialize(app)
        @app = app
      end
      
      def call(env)
        status, headers, body = @app.call(env)
        @response = Rack::Response.new(body, status, headers)
        if @response.redirect? && env["rack-bug.intercept_redirects"]
          intercept_redirect
        end
        @response.to_a
      end
      
      def intercept_redirect
         redirect_to = @response.location
         new_body = render_template("redirect", :redirect_to => @response.location)
         new_response = Rack::Response.new(new_body, 200, { "Content-Type" => "text/html" })
         new_response["Content-Length"] = new_body.size.to_s
         @response = new_response
       end
      
    end
  end
end