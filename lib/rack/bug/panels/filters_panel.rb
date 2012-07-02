module Rack
  class Bug

    class FiltersPanel < Panel
      require "rack/bug/panels/filters_panel/action_controller_extension"

      autoload :Trace,      "rack/bug/panels/filters_panel/trace"
      autoload :Rendering,  "rack/bug/panels/filters_panel/rendering"

      def self.record(filter, &block)
        return block.call unless Rack::Bug.enabled?

        filter_trace.start(filter)
        result = block.call
        filter_trace.finished(filter)
        return result
      end

      def self.reset
        Thread.current["rack.bug.filter_trace"] = Trace.new
      end

      def self.filter_trace
        Thread.current["rack.bug.filter_trace"] ||= Trace.new
      end

      def name
        "filters"
      end

      def heading
        "Filters: %.2fms" % (self.class.filter_trace.total_time * 1_000)
      end

      def content
        result = render_template "panels/filters", :filter_trace => self.class.filter_trace
        self.class.reset
        return result
      end

    end

  end
end
