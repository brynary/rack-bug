class Rack::Bug
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
end