module Rack
  class Bug

    class RequestVariablesPanel < Panel

      def name
        "request_variables"
      end

      def before(env)
        @env = env
      end

      def heading
        "Rack Env"
      end

      def content
        sections = {}
        sections["GET"] = sort(@request.GET) if @request.GET.any?
        sections["POST"] = sort(@request.GET) if @request.POST.any?
        sections["Session"] = sort(@request.env["rack.session"]) if @request.env["rack.session"] && @request.env["rack.session"].any?
        sections["Cookies"] = sort(@request.env["rack.request.cookie_hash"]) if @request.env["rack.request.cookie_hash"] && @request.env["rack.request.cookie_hash"].any?
        server, rack = split_and_filter_env(@env)
        sections["SERVER VARIABLES"] = sort(server)
        sections["Rack ENV"] = sort(rack)
        render_template "panels/request_variables", :sections => sections
      end

    private
      def sort(hash)
        hash.sort_by { |k, v| k.to_s }
      end

      def split_and_filter_env(env)
        server, rack = {}, {}
        env.each do |k,v|
          if k.index("rack.") == 0
            rack[k] = v
          elsif k.index("rack-bug.") == 0
            #don't output the rack-bug variables - especially secret_key
          else
            server[k] = v
          end
        end
        return server, rack
      end

    end

  end
end
