module Rack::Insight
  class TemplatesPanel
    class Stats
      require 'rack/insight/panels/templates_panel/rendering'

      include Rack::Insight::Logging

      attr_reader :root, :current

      def initialize(*args)
        @root = Rack::Insight::TemplatesPanel::Rendering.new(*args)
        @current = @root
      end

      # Track when each template starts being rendered
      def begin_record!(rendering)
        @current.add!(rendering) # Add the rendering as a child of the current and make rendering the new current
        @current = rendering
      end

      # Track when each template finishes being rendered, move current back up the rendering chain
      def finish_record!(timing)
        # This is the one being completed now, and for which we now know the timing duration
        @current.finish!(timing)
        # Prepare for the next template to finish
        @current = @current.parent
      end

      def finish!
        @root.finish!(root._calculate_child_time)
        @current = nil
      end

      def to_s
        "#{self.root.to_s}"
      end

    end
  end
end
