require 'insight/logger'

module Insight
  class PathFilter
    include Logging
    def initialize(app)
      @app = app
    end

    def call(env)
      filters = env['insight.path_filters'].map do |string|
        %r{^#{string}}
      end

      unless filter = filters.find{|regex| regex =~ env['PATH_INFO']}
        return [404, {}, []]
      end

      logger.debug{ "Shortcutting collection stack: #{filter} =~ #{env['PATH_INFO']}"}
      return @app.call(env)
    end
  end
end
