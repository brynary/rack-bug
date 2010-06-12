module Rack
  class Bug
    class TemplatesPanel

      class Rendering
        attr_accessor :name
        attr_accessor :start_time
        alias_method :time, :start_time
        attr_accessor :end_time
        attr_accessor :parent
        attr_reader :children

        def initialize(name, start_time = nil, end_time = nil)
          @name = name
          @start_time = start_time || Time.now
          @end_time = end_time
          @children = []
        end

        def add(rendering)
          @children << rendering
          rendering.parent = self
        end

        def delete(rendering)
          @children.delete(rendering)
        end
        
        def duration
          if @end_time
            @end_time - @start_time
          else
            child_duration
          end
        end

        def exclusive_duration
          duration - child_duration
        end

        def child_duration
          children.inject(0.0) { |memo, c| memo + c.duration }
        end

        def duration_summary
          if children.any?
            "%.2fms, %.2f exclusive" % [duration * 1_000, exclusive_duration * 1_000]
          else
            "%.2fms" % (duration * 1_000)
          end
        end
        def html
          <<-HTML
            <li>
              <p>#{name} (#{duration_summary})</p>

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
