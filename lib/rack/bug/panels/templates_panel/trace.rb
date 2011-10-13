module Rack
  class Bug
    class TemplatesPanel

      class Trace

        def start(template_name)
          rendering = Rendering.new(template_name)
          rendering.start_time = Time.now
          @current.add(rendering)
          @current = rendering
        end
        
        def add(template_name, start_time, end_time, event)
          current = Rendering.new(template_name, start_time, end_time)
          root_rendering.children.each do |child|
            next unless event.parent_of?(child)
            root_rendering.delete(child)
            current.add(child)
          end
          root_rendering.add(current)
        end

        def finished(template_name)
          @current.end_time = Time.now
          @current = @current.parent
        end

        def initialize
          @current = root_rendering
        end

        def total_time
          root_rendering.duration
        end

        def root_rendering
          @root_rendering ||= Rendering.new("root")
        end
      end

    end
  end
end
