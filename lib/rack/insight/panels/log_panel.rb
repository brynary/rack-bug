module Rack::Insight
  class LogPanel < Panel
    class LogEntry
      # TODO: Update this to the Rack::Insight panel format
      attr_reader :level, :time, :message
      LEVELS = ['DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL'] unless defined?(LEVELS)

      def initialize(level, time, message)
        @level = LEVELS[level]
        @time = time
        @message = message
      end

      def cleaned_message
        @message.to_s.gsub(/\e\[[;\d]+m/, "")
      end
    end

    def after_detect(method_call, timing, args, message)
      message = args[1] || args[2] unless message.is_a?(String)
      log_level = args[0]
      store(@env, LogEntry.new(log_level, timing.delta_t, message))
    end

    def initialize(app)

      # Call super before setting up probes in case there are any custom probes configured
      super # will setup custom probes

      unless is_probing?
        probe(self) do
          # Trying to be smart...
          if defined?(ActiveSupport)
            instrument "ActiveSupport::BufferedLogger" do
              instance_probe :add
            end
          else
            instrument "Logger" do
              instance_probe :add
            end
          end
        end
      end
    end

    def content_for_request(number)
      render_template "panels/log", :logs => retrieve(number)
    end
  end

end
