module Insight

  class TemplatesPanel < Panel
    autoload :Trace,      "insight/panels/templates_panel/trace"
    autoload :Rendering,  "insight/panels/templates_panel/rendering"

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
      @current = Rendering.new("root")
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
