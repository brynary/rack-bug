require "ipaddr"
require "digest"

require "rack/bug/options"

Dir[File.dirname(__FILE__) + "/panels/*.rb"].each do |panel_name|
  require "rack/bug/panels/" + File.basename(panel_name)
end

module Rack
  module Bug
    
    class Toolbar
      include Rack::Bug::Options
      
      MIME_TYPES = ["text/html", "application/xhtml+xml"]
      
      def initialize(app, options = {})
        @app = asset_server(app)
        initialize_options options
        instance_eval(&block) if block_given?
      end
      
      def asset_server(app)
        Rack::Static.new(app, :urls => ["/__rack_bug__"], :root => public_path)
      end
      
      def public_path
        ::File.expand_path(::File.dirname(__FILE__) + "/../bug/public")
      end
      
      def call(env)
        @env = @default_options.merge(env)
        
        if authorized?(@env)
          dispatch(@env)
        else
          @app.call(@env)
        end
      end
      
      def dispatch(env)
        status, headers, body = builder.call(@env)
        response = Rack::Response.new(body, status, headers)
        inject_into(response) if modify?(@env, response)
        return response.to_a
      end
      
      def authorized?(env)
        ip_authorized?(env) && password_authorized?(env)
      end
      
      def ip_authorized?(env)
        return true unless options["rack-bug.ip_masks"]
        
        options["rack-bug.ip_masks"].any? do |ip_mask|
          ip_mask.include?(IPAddr.new(env["REMOTE_ADDR"]))
        end
      end
      
      def password_authorized?(env)
        return true unless options["rack-bug.password"]
        
        expected_sha = Digest::SHA1.hexdigest ["rack_bug", options["rack-bug.password"]].join(":")
        actual_sha = Request.new(env).cookies["rack_bug_password"]
        
        actual_sha == expected_sha
      end
      
      def modify?(env, response)
        response.ok? &&
        env["X-Requested-With"] != "XMLHttpRequest" &&
        MIME_TYPES.include?(response.content_type)
      end
      
      def builder
        builder = Rack::Builder.new
        
        options["rack-bug.panel_classes"].each do |panel_class|
          builder.use panel_class
        end
        
        builder.run @app
        
        return builder
      end
      
      def inject_into(response)
        full_body = response.body.join
        full_body.sub! /<\/body>/, render + "</body>"
        
        response["Content-Length"] = full_body.size.to_s
        response.body = [full_body]
      end
      
      def render
        @panels = @env["rack-bug.panels"].reverse
        @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/../bug/views/bug.html.erb")
        @template.result(binding)
      # rescue
      #   @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/../bug/views/error.html.erb")
      #   @template.result(binding)
      end
      
    end
    
  end
end