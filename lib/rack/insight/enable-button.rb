require "rack/toolbar"

module Rack::Insight
  class EnableButton < Rack::Toolbar
    include Render

    def okay_to_modify?
      super
      return !match_path_filters?(@env["rack-insight.path_filters"], @env["REQUEST_PATH"])
    end

    def match_path_filters?(path_filters, path)
      to_regex(path_filters).find { |filter| path =~ filter }
    end

    def to_regex(filters)
      (filters || []).map { |str| %r(^#{str}) }
    end

    def render
      render_template("enable-button")
    end
  end
end
