module Rack
  module Bug
    class TemplatesPanel
      
      class Rendering
        attr_accessor :name
        attr_accessor :start_time
        attr_accessor :end_time
        attr_accessor :parent
        attr_reader :children
        
        
        def initialize(name)
          @name = name
          @children = []
        end
        
        def add(rendering)
          @children << rendering
          rendering.parent = self
        end
        
        def time
          @end_time - @start_time
        end
        
        def exclusive_time
          time - child_time
        end
        
        def child_time
          children.inject(0.0) { |memo, c| memo + c.time }
        end
        
        def time_summary
          if children.any?
            "%.2fms, %.2f exclusive" % [time * 1_000, exclusive_time * 1_000]
          else
            "%.2fms" % (time * 1_000)
          end
        end
        def html
          <<-HTML
            <li>
              <p>#{name} (#{time_summary})</p>
              
              #{children_html}
            </li>
          HTML
        end
        
        def children_html
          return "" unless children.any?
          
          <<-HTML
            <ul>#{joined_children_html}</ul>
          HTML
        end
        
        def joined_children_html
          children.map { |c| c.html }.join
        end
      end
      
    end
  end
end