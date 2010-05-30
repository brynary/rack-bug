require "rack/bug/panels/log_panel/rails_extension"

module Rack
  class Bug

    class LogPanel < Panel
      class LogEntry
        attr_reader :level, :time, :message
        LEVELS = ['DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL']

        def initialize(level, time, message)
          @level = LEVELS[level]
          @time = time
          @message = message
        end

        def cleaned_message
          @message.to_s.gsub(/\e\[[;\d]+m/, "")
        end
      end

      def self.record(message, log_level)
        return unless Rack::Bug.enabled?
        return unless message
        Thread.current["rack.bug.logs.start"] ||= Time.now
        timestamp = ((Time.now - Thread.current["rack.bug.logs.start"]) * 1000).to_i
        logs << LogEntry.new(log_level, timestamp, message)
      end

      def self.reset
        Thread.current["rack.bug.logs"] = []
        Thread.current["rack.bug.logs.start"] = nil
      end

      def self.logs
        Thread.current["rack.bug.logs"] ||= []
      end

      def name
        "log"
      end

      def heading
        "Log"
      end

      def content
        result = render_template "panels/log", :logs => self.class.logs
        self.class.reset
        return result
      end

    end

  end
end
