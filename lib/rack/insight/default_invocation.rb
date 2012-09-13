# For Magic Panels
module Rack::Insight
  class DefaultInvocation < Struct.new :method, :time, :arguments, :result, :backtrace
    attr_accessor :method, :time, :arguments, :result, :backtrace

    include Rack::Insight::FilteredBacktrace
    include Rack::Insight::MagicInsight

    def initialize(*args)
      @method = args[0]
      @time = [args[1].duration, args[1].delta_t]
      @arguments = args[2]
      @result = args[3]
      @backtrace = args[4]
    end

    def human_time
      "%.2fms" % (self.time * 1_000)
    end

  end
end
