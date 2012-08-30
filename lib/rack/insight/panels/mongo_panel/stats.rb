module Rack::Insight
  class MongoPanel

    class Stats
      class Query
        attr_reader :time
        attr_reader :command

        def initialize(time, command)
          @time = time
          @command = command
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

      def record_call(time, command)
        @queries << Query.new(time, command)
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
