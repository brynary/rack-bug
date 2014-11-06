module Rack::Insight
  class RequestVariablesPanel < Panel

    def after(env,status,headers,body)
      sections = {}
      sections["GET"] = sort(@request.GET) if @request.GET.any?
      sections["POST"] = sort(@request.POST) if @request.POST.any?
      # TODO: Better Fix for Rails 4 (as part of splitting panels into separate gems)
      if defined?(ActionDispatch::Request::Session)
        sections["Session"] = sort(@request.env["rack.session"].to_hash) if @request.env["rack.session"] && @request.env["rack.session"].present?
      else
        sections["Session"] = sort(@request.env["rack.session"]) if @request.env["rack.session"] && @request.env["rack.session"].any?
      end
      sections["Cookies"] = sort(@request.env["rack.request.cookie_hash"]) if @request.env["rack.request.cookie_hash"] && @request.env["rack.request.cookie_hash"].any?
      server, rack = split_and_filter_env(@env)
      sections["SERVER VARIABLES"] = sort(server)
      sections["Rack ENV"] = sort(rack)

#      require 'pp'
#      ::File.open("sections.dump", "w") do |file|
#        PP.pp(sections, file)
#      end
      store(env, sections)
    end

    def heading
      "Rack Env"
    end

    def content_for_request(number)
      sections = retrieve(number).first

      render_template "panels/request_variables", :sections => sections
    end

    private
    def sort(hash)
      scrub(hash.sort_by { |k, v| k.to_s })
    end

    def scrub(enum)
      enum.map do |k,v|
        if Hash === v
          [k, v.inspect]
        else
          [k, v.to_s]
        end
      end
    end

    def split_and_filter_env(env)
      server, rack = {}, {}
      env.each do |k,v|
        if k.index("rack.") == 0
          rack[k] = v
        elsif k.index("rack-insight") == 0 or k.index("rack-insight") == 0
          #don't output the insight variables - especially secret_key
        else
          server[k] = v
        end
      end
      return server, rack
    end

  end
end
