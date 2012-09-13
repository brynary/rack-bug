module Rack::Insight
  class TemplatesPanel

    class Rendering

      include Rack::Insight::MagicInsight

      attr_accessor :template
      attr_accessor :partial
      attr_accessor :parent
      attr_reader :children

      # '_' prevents MagicInsight template from calling the method
      # Time tracking
      attr_accessor :_time, :_exclusive_time, :_child_time

      def initialize(template)
        @template = template.to_s
        @partial = template.partial ? 'yes' : 'no' if template.respond_to?(:partial)
        @_time = 0
        @_exclusive_time = 0
        @_child_time = 0
        @children = []
        @parent = nil
      end

      # called from Stats#begin_record
      def add!(rendering)
        @children << rendering
        rendering.parent = self
      end

      # LOL what?
      #def delete(rendering)
      #  @children.delete(rendering)
      #end

      def finish!(timing)
        self._time = timing || 0
        self._child_time = _calculate_child_time
        self._exclusive_time = _calculate_exclusive_time
      end

      def _calculate_exclusive_time
        _time - _child_time
      end

      def _calculate_child_time
        children.inject(0.0) { |memo, c| memo + c._time } || 0
      end

      def _human_time(t = self._time)
        "%.2fms" % t
      end

      def time_summary
        if children.any?
          "#{_human_time}, (exclusive: #{_human_time(_exclusive_time)}, child: #{_human_time(_child_time)})"
        else
          _human_time
        end
      end

      def to_s
        "#{template} (#{time_summary})#{!children.empty? ? " (#{children.length} children)\n#{children.map {|x| x.to_s}.join("\n")}" : ''}"
      end

    end

  end
end
