module Rack::Insight
  class RailsInfoPanel < Panel

    self.tableless = true

    def heading
      return unless (defined?(Rails) && defined?(Rails::Info))
      "Rails #{Rails.version}"
    end

    def content
      return unless (defined?(Rails) && defined?(Rails::Info))
      render_template "panels/rails_info"
    end

  end
end
