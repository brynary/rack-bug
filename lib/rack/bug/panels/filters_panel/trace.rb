module Rack
  class Bug
    class FiltersPanel

      class Trace

        def start(filter)
          
          rendering = Rendering.new(filter)
          rendering.start_time = Time.now
          @current.add(rendering)
          @current = rendering
        end

        def finished(filter)
          @current.end_time = Time.now
          @current = @current.parent
        end

        def initialize
          @current = root
        end

        def total_time
          root.child_time
        end

        def root
          @root ||= Rendering.new("root")
        end
      end

    end
  end
end
