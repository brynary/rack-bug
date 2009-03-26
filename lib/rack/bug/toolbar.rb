require "ipaddr"
require "digest"

require "rack/bug/options"
require "rack/bug/render"

Dir[File.dirname(__FILE__) + "/panels/*.rb"].each do |panel_name|
  require "rack/bug/panels/" + File.basename(panel_name)
end

module Rack
  module Bug
    
    class RackStaticBugAvoider
      def initialize(app, static_app)
        @app = app
        @static_app = static_app
      end
      
      def call(env)
        if env["PATH_INFO"]
          @static_app.call(env)
        else
          @app.call(env)
        end
      end
    end
    
    class Toolbar
      include Options
      include Render
      
      MIME_TYPES = ["text/html", "application/xhtml+xml"]
      AJAX_MIME_TYPES = ["text/javascript", "application/json"]
      
      def initialize(app, options = {})
        @app = Rack::Cascade.new([toolbar_app, asset_server(app)])
        initialize_options options
        instance_eval(&block) if block_given?
      end
      
      def asset_server(app)
        RackStaticBugAvoider.new(app, Rack::Static.new(app, :urls => ["/__rack_bug__"], :root => public_path))
      end
      
      def public_path
        ::File.expand_path(::File.dirname(__FILE__) + "/../bug/public")
      end
      
      def call(env)
        @env = @default_options.merge(env)
        @env["rack-bug.panels"] = []
        @original_request = Request.new(@env)

        if toolbar_requested? && ip_authorized? && password_authorized?
          dispatch
        else
          pass
        end
      end
      
      def pass
        @app.call(@env)
      end
      
      def dispatch
        status, headers, body = builder.call(@env)
        @response = Rack::Response.new(body, status, headers)
        
        if @response.redirect? && options["rack-bug.intercept_redirects"]
          intercept_redirect
        elsif modify?
          inject_toolbar
        elsif ajax?
          store_toolbar
          inject_toolbar_notification
        end
        
        return @response.to_a
      end
      
      def intercept_redirect
        redirect_to = @response.location
        new_body = render_template("redirect", :redirect_to => @response.location)
        new_response = Rack::Response.new(new_body, 200, { "Content-Type" => "text/html" })
        new_response["Content-Length"] = new_body.size.to_s
        @response = new_response
      end
      
      def toolbar_requested?
        @original_request.cookies["rack_bug_enabled"]
      end
      
      def ip_authorized?
        return true unless options["rack-bug.ip_masks"]
        
        options["rack-bug.ip_masks"].any? do |ip_mask|
          ip_mask.include?(IPAddr.new(@original_request.ip))
        end
      end
      
      def password_authorized?
        return true unless options["rack-bug.password"]
        
        expected_sha = Digest::SHA1.hexdigest ["rack_bug", options["rack-bug.password"]].join(":")
        actual_sha = @original_request.cookies["rack_bug_password"]
        
        actual_sha == expected_sha
      end
      
      def modify?
        @response.ok? &&
        !ajax? &&
        MIME_TYPES.include?(@response.content_type.split(";").first)
      end
      
      def ajax?
        @env["X-Requested-With"] == "XMLHttpRequest" ||
        AJAX_MIME_TYPES.include?(@response.content_type.split(";").first)
      end
      
      def builder
        builder = Rack::Builder.new
        
        options["rack-bug.panel_classes"].each do |panel_class|
          builder.use panel_class
        end
        
        builder.run @app
        
        return builder
      end
      
      class ToolbarApp < Sinatra::Default
        include Rack::Bug::Render
          
        get "/__rack_bug__/update_toolbar" do
          raise "Rails not found... can't read key" unless defined?(Rails)
          "$('#rack_bug').replaceWith(#{Rails.cache.read(params[:key]).to_json});"
        end
      end
      
      def toolbar_app
        ToolbarApp.new
      end
      
      def inject_toolbar
        full_body = @response.body.join
        full_body.sub! /<\/body>/, render + "</body>"
        
        @response["Content-Length"] = full_body.size.to_s
        @response.body = [full_body]
      end
      
      def store_toolbar
        return unless defined?(Rails)
        Rails.cache.write("rack-bug.#{@original_request.path_info}", render)
        "OK"
      end
      
      def inject_toolbar_notification
        @response["__Rack_Bug__"] = "rack-bug.#{@original_request.path_info}"
      end
      
      def render
        render_template("bug", :panels => @env["rack-bug.panels"].reverse)
      end
      
    end
    
  end
end