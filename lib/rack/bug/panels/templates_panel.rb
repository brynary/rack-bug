module Rack
  class Bug

    class TemplatesPanel < Panel
      autoload :Trace,      "rack/bug/panels/templates_panel/trace"
      autoload :Rendering,  "rack/bug/panels/templates_panel/rendering"

      def initialize(app)
        super

        probe(self) do
          instrument "ActionView::Template" do
            instance_probe :render
          end
        end

        table_setup("templates")

        @current = nil
      end


      def request_start(env, start)
        @current = root_rendering
      end

      def request_finish(env, status, headers, body, timing)
        store(env, @current)
        @current = nil
      end

      def before_detect(method_call, args)
        template_name = method_call.object.virtual_path

        rendering = Rendering.new(template_name)
        @current.add(rendering)
        @current = rendering
      end

      def after_detect(method_call, timing, args, result)
        @current.timing = timing
        @current = @current.parent
      end

      def total_time
        root_rendering.duration
      end

      def root_rendering
        @root_rendering ||= Rendering.new("root")
      end

      #XXX ???
      def add(template_name, start_time, end_time, event)
        current = Rendering.new(template_name, start_time, end_time)
        root_rendering.children.each do |child|
          next unless event.parent_of?(child)
          root_rendering.delete(child)
          current.add(child)
        end
        root_rendering.add(current)
      end

      #XXX ???
      def self.record_event(event)
        return unless Rack::Bug.enabled?

        template_description = "#{event.name}: #{event.payload[:virtual_path] || event.payload[:identifier]}"
        template_trace.add(template_description, event.time, event.end, event)
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

      def heading_for_request(number)
        "Templates: %.2fms" % (retrieve(number).inject(0.0){|memo, rendering| memo + rendering.duration})
      end

      def content_for_request(number)
        result = render_template "panels/templates", :root_rendering => retrieve(number).first
        return result
      end

    end

  end
end
