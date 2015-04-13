module Rack::Insight
  class Toolbar < Rack::Toolbar
    include Render
    include Logging
    include PathMatchFilters

    def initialize(app, insight, options = {})
      super app, options
      @insight = insight
      @request_table = Database::RequestTable.new
    end

    def okay_to_modify?
      super
      return !match_path_filters?(@env["rack-insight.path_filters"], @env["REQUEST_PATH"])
    end

    # Ensure that browser doesn't cache
    def ensure_no_cache
      @headers["Etag"] = ""
      @headers["Cache-Control"] = "no-cache"
    end

    def req_id
      @req_id ||= (@env['rack-insight.request-id'] || @request_table.last_request_id).to_i
    end

    def requests
      @requests ||= @request_table.to_a.map do |row|
        { :id => row[0], :method => row[1], :path => row[2] }
      end
    end

    def headers_fragment
      render_template("headers_fragment",
                      :request_id => req_id,
                      :panels => @insight.panels,
                      :handle_javascript => @insight.config[:handle_javascript])
    end

    def current_request_fragment
      render_template("request_fragment",
                      :request_id => req_id,
                      :panels => @insight.panels,
                      :requests => requests)
    end

    def render
      ensure_no_cache

      unless verbose(:silent)
        logger.info do
          "Injecting toolbar: active panels: #{@insight.panels.map{|pnl| pnl.class.name}.inspect}"
        end
      end

      html = render_template("toolbar",
                             :request_id => req_id,
                             :request_fragment => current_request_fragment,
                             :headers_fragment => headers_fragment,
                             :handle_javascript => Rack::Insight::Config.config[:handle_javascript])
      html.force_encoding('UTF-8') if RUBY_VERSION > '1.9.0'
      html
    end
  end
end
