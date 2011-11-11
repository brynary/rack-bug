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
      instrument "ActiveSupport::BufferedLogger" do
        instance_probe :add
      end

      instrument "Logger" do
        instance_probe :add
      end
    end

    table_setup("log_entries")

    super
  end

  def name
    "log"
  end

  def heading
    "Log"
  end

  def content_for_request(number)
    render_template "panels/log", :logs => retrieve(number)
  end
end

end
