module Rack::Insight
  class RedisPanel

    class Stats
      class Query
        include Rack::Insight::FilteredBacktrace

        attr_reader :time
        attr_reader :command

        def initialize(time, command_args, method_call)
          @time = time
          @command = command_args.inspect
          @backtrace = method_call.backtrace
        end

        def display_time
          "%.2fms" % time
        end
      end

      attr_reader :calls
      attr_reader :queries

      def initialize
        @queries = []
        @calls = 0
        @time = 0.0
      end

      def record_call(time, command_args, method_call)
        @queries << Query.new(time, command_args, method_call)
        #puts "Recorded Redis Call: #{@queries.inspect}"
        @calls += 1
        @time += time
      end

      def display_time
        "%.2fms" % time
      end

      def time
        @queries.inject(0) do |memo, query|
          memo + query.time
        end
      end

    end

  end
end
