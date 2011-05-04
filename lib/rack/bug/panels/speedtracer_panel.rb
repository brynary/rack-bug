require 'rack/bug'
#require 'yajl'
require 'uuid'

require 'rack/bug/panels/speedtracer_panel/trace-app'
require 'rack/bug/panels/speedtracer_panel/tracer'

class Rack::Bug
  class SpeedTracerPanel < Panel
    def self.database
      @db ||= {}
    end

    def database
      self.class.database
    end

    def initialize(app)
      @app  = app
      @uuid = UUID.new
      super
    end

    def panel_app
      return SpeedTrace::TraceApp.new(database)
    end

    def name
      "speedtracer"
    end

    def heading
      "#{database.keys.length} traces"
    end

    def content
      render_template "panels/speedtracer/traces", :traces => database
    end

    def before(env)
      env['st.id']   = @uuid.generate

      tracer = SpeedTrace::Tracer.new(env['st.id'], env['REQUEST_METHOD'], env['REQUEST_URI'])
      env['st.tracer'] = tracer
      Thread::current['st.tracer'] = tracer
    end

    def after(env, status, headers, body)
      env['st.tracer'].finish
      database[env['st.id']] = env['st.tracer']
      headers['X-TraceUrl'] = '/speedtracer?id=' + env['st.id']
    end
  end
end

require 'rack/bug/panels/speedtracer_panel/instrument'
