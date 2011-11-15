module Insight
  class Logger
    def initialize(level, path)
      @level = level
      @log_path = path
      @logfile = nil
    end

    attr_accessor :level

    DEBUG    =  0
    INFO     =  1
    WARN     =  2
    ERROR    =  3
    FATAL    =  4
    UNKNOWN  =  5

    def log(severity, message)
      if defined? Rails and
        Rails.respond_to? :logger
        not Rails.logger.nil?
        Rails.logger.add(severity, "[Insight]: " + message)
      end

      if severity >= @level
        logfile.puts(message)
      end
    end

    def logfile
      @logfile ||= File::open(@log_path, "a+")
    rescue
      $stderr
    end

    def debug;   log(DEBUG,   yield) if @level >= DEBUG;   end
    def info;    log(INFO,    yield) if @level >= INFO;    end
    def warn;    log(WARN,    yield) if @level >= WARN;    end
    def error;   log(ERROR,   yield) if @level >= ERROR;   end
    def fatal;   log(FATAL,   yield) if @level >= FATAL;   end
    def unknown; log(UNKNOWN, yield) if @level >= UNKNOWN; end
  end

  module Logging
    def logger(env = nil)
      if env.nil?
        Thread.current['insight.logger']
      else
        env["insight.logger"]
      end
    end
  end
end
