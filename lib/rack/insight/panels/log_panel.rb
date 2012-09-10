module Rack::Insight
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

    def after_detect(method_call, timing, args, message)
      message = args[1] || args[2] unless message.is_a?(String)
      log_level = args[0]
      store(@env, LogEntry.new(log_level, timing.delta_t, message))
    end

    def initialize(app)
      probe(self) do
        if !Rack::Insight::Config.config[:panel_configs][:log_panel].respond_to?(:[])
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
        else
          # User has explicitly declared what log classes to monitor:
          #   Rack::Insight::Config.configure do |config|
          #     config[:panel_configs][:log_panel] = {:watch => {'Logger' => :add}}
          #   end
          Rack::Insight::Config.config[:panel_configs][:log_panel][:watch].each do |klass, method_probe|
            instrument klass do
              instance_probe method_probe
            end
          end
        end
      end

      table_setup("log_entries")

      super
    end

    def name
      "log"
    end

    def heading
      stats = retrieve(number).first

      "#{stats.queries.size} Log Lines"
    end

    def content_for_request(number)
      render_template "panels/log", :logs => retrieve(number)
    end
  end

end
