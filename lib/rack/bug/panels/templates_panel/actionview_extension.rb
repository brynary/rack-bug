if defined?(ActionView) && defined?(ActionView::Template)
  if defined?(ActiveSupport::Notifications)

    ActiveSupport::Notifications.subscribe /^render.*\.action_view/ do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      Rack::Bug::TemplatesPanel.record_event(event)
    end

  else
    ActionView::Template.class_eval do

      def render_template_with_rack_bug(*args, &block)
        Rack::Bug::TemplatesPanel.record(path_without_format_and_extension) do
          render_template_without_rack_bug(*args, &block)
        end
      end

      alias_method_chain :render_template, :rack_bug
    end
  end
end
