module Rack::Insight
  class EnableButton < Rack::Toolbar
    include Render
    include PathMatchFilters

    def okay_to_modify?
      super
      return !match_path_filters?(@env["rack-insight.path_filters"], @env["REQUEST_PATH"])
    end

    def render
      render_template("enable-button")
    end
  end
end
