module Rack::Insight
  class SphinxPanel

    class Stats
      class Query
        include Rack::Insight::FilteredBacktrace

        attr_reader :time
        attr_reader :command

        def initialize(time, command_args, method_call)
          riddle_command, messages = *command_args
          @time = time
          if riddle_command == :search
            @command = "search: " + decode_message(messages.first).collect{|k,v| "#{k} => #{v}"}.join(", ")
          else
            @command = command_args.inspect + ": No more info is available for this Sphinx request type"
          end
          @backtrace = method_call.backtrace
        end

        def display_time
          "%.2fms" % time
        end

        def decode_message(m)
          @m = m.clone
          params = ActiveSupport::OrderedHash.new

          params[:offset] = consume_int
          params[:limit] = consume_int
          params[:match_mode] = consume_int
          params[:rank_mode] = consume_int
          params[:sort_mode] = consume_int
          params[:sort_by] = consume_string
          params[:query] = consume_string
          wl = consume_int
          weights = []
          wl.times do weights << consume_int end
          params[:weights] = weights

          params[:index] = consume_string

          consume_string

          params[:id_range] = [consume_64int, consume_64int]
          params
        end

        def consume_int
          i = @m.unpack("N").first
          @m = @m.slice(4, @m.length - 4)
          i
        end

        def consume_64int
          i = @m.unpack("NN").first
          @m = @m.slice(8, @m.length - 8)
          i
        end

        def consume_string
          len = consume_int
          s = @m.slice(0, len)
          @m = @m.slice(len, @m.length - len)
          s
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
