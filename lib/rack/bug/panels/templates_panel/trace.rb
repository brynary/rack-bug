module Rack
  module Bug
    class TemplatesPanel
      
      class Trace
        
        def start(template_name)
          rendering = Rendering.new(template_name)
          rendering.start_time = Time.now
          @current.add(rendering)
          @current = rendering
        end
        
        def finished(template_name)
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