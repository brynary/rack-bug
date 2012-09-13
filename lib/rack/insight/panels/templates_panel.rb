module Rack::Insight
  class TemplatesPanel < Panel
    require "rack/insight/panels/templates_panel/stats"

    def request_start(env, start)
      @stats = Rack::Insight::TemplatesPanel::Stats.new("root")
    end

    def request_finish(env, status, headers, body, timing)
      @stats.finish!
      store(env, @stats)
      @stats = nil
    end

    def before_detect(method_call, args)
      template_name = method_call.object.virtual_path
      rendering = Rendering.new(template_name)
      @stats.begin_record!(rendering)
    end

    def after_detect(method_call, timing, args, result)
      @stats.finish_record!(timing.duration)
    end

    def heading_for_request(number)
      "Templates: #{heading_time(number)}"
    end

    def heading_time(number)
      stat = retrieve(number).first
      if stat.respond_to?(:root)
        if stat.root.respond_to?(:_human_time)
          stat.root._human_time
        end
      end
    end

    def content_for_request(number)
      stat = retrieve(number).first
      rendering_root = stat.root if stat.respond_to?(:root)
      if rendering_root
        render_template 'magic_panel', :magic_insights => rendering_root.children, :name => "Templates: #{(rendering_root._human_time)}"
      else
        render_template 'no_data', :name => self.camelized_name
      end
    end

  end
end
