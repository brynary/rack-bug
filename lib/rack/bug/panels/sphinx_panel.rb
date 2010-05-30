module Rack
  class Bug

    class SphinxPanel < Panel
      require "rack/bug/panels/sphinx_panel/sphinx_extension"

      autoload :Stats, "rack/bug/panels/sphinx_panel/stats"

      def self.record(*sphinx_command_args, &block)
        return block.call unless Rack::Bug.enabled?

        start_time = Time.now
        result = block.call
        total_time = Time.now - start_time
        stats.record_call(total_time * 1_000, sphinx_command_args)
        return result
      end

      def self.reset
        Thread.current["rack.bug.sphinx"] = Stats.new
      end

      def self.stats
        Thread.current["rack.bug.sphinx"] ||= Stats.new
      end

      def name
        "sphinx"
      end

      def heading
        "Sphinx: %.2fms (#{self.class.stats.queries.size} calls)" % self.class.stats.time
      end

      def content
        result = render_template "panels/sphinx", :stats => self.class.stats
        self.class.reset
        return result
      end

    end

  end
end
