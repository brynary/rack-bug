require 'rack/insight/logging'

module Rack::Insight
  class PathFilter
    include Rack::Insight::Logging
    def initialize(app)
      @app = app
    end

    def call(env)
      filters = env['rack-insight.path_filters'].map do |string|
        %r{^#{string}}
      end

      unless filter = filters.find{|regex| regex =~ env['PATH_INFO']}
        return [404, {}, []]
      end

      logger.debug{ "Shortcutting collection stack: #{filter} =~ #{env['PATH_INFO']}"} if verbose(:debug)
      return @app.call(env)
    end
  end
end
