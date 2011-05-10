module Rack
  class Bug

    class TemplatesPanel < Panel
      require "rack/bug/panels/templates_panel/actionview_extension"

      autoload :Trace,      "rack/bug/panels/templates_panel/trace"
      autoload :Rendering,  "rack/bug/panels/templates_panel/rendering"

      def self.record(template)
        return yield unless Rack::Bug.enabled?

        template_trace.start(template)
        begin
          result = yield
        ensure
          template_trace.finished(template)
        end
        return result
      end

      def self.reset
        Thread.current["rack.bug.template_trace"] = Trace.new
      end

      def self.template_trace
        Thread.current["rack.bug.template_trace"] ||= Trace.new
      end

      def name
        "templates"
      end

      def heading
        "Templates: %.2fms" % (self.class.template_trace.total_time * 1_000)
      end

      def content
        result = render_template "panels/templates", :template_trace => self.class.template_trace
        self.class.reset
        return result
      end

    end

  end
end
