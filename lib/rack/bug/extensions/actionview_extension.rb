if defined?(ActionView) && defined?(ActionView::Template)
  ActionView::Template.class_eval do

    def render_template_with_rack_test(*args, &block)
      Rack::Bug::TemplatesPanel.record(path_without_format_and_extension) do
        render_template_without_rack_test(*args, &block)
      end
    end

    alias_method_chain :render_template, :rack_test
  end
end