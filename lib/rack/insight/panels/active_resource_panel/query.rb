module Rack::Insight
  class ActiveResourcePanel
    class RequestResult
      include Rack::Insight::FilteredBacktrace

      attr_reader :path, :args, :result, :time
      alias results result

      def initialize(path, args, time, backtrace = [], result=nil)
        @path = path
        @args = args
        @time = time
        @backtrace = backtrace
        @result = result
      end

      def human_time
        "%.2fms" % (@time)
      end

      def valid_hash?(secret_key, possible_hash)
        hash = Digest::SHA1.hexdigest [secret_key, @sql].join(":")
        possible_hash == hash
      end
    end
  end
end
