module Rack
  class Bug
    class TemplatesPanel

      class Rendering
        attr_accessor :name
        attr_accessor :parent
        attr_accessor :timing
        attr_reader :children

        def initialize(name, timing = nil)
          @name = name
          @timing = timing
          @children = []
        end

        def start_time
          @timing.start
        end
        alias_method :time, :start_time

        def end_time
          @timing.end
        end

        def add(rendering)
          @children << rendering
          rendering.parent = self
        end

        def delete(rendering)
          @children.delete(rendering)
        end

        def duration
          if @timing
            @timing.duration
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
            "%.2fms, %.2f exclusive" % [duration, exclusive_duration]
          else
            "%.2fms" % (duration)
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
