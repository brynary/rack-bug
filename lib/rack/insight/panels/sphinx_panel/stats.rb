module Rack::Insight
  class SphinxPanel

    class Stats
      class Query
        include Rack::Insight::FilteredBacktrace

        require 'riddle/client'
        MatchModes = Riddle::Client::MatchModes.invert
        RankModes = Riddle::Client::RankModes.invert
        SortModes = Riddle::Client::SortModes.invert
        AttributeTypes = Riddle::Client::AttributeTypes.invert
        GroupFunctions = Riddle::Client::GroupFunctions.invert
        FilterTypes = Riddle::Client::FilterTypes.invert

        attr_reader :time
        attr_reader :command

        def initialize(time, command_args, method_call)
          riddle_command, messages = *command_args
          @time = time
          if riddle_command == :search
            @command = "search: " + decode_message(messages.first).inspect
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

          # Mode, Limits
          params[:offset] = consume_int
          params[:limit] = consume_int
          params[:match_mode] = MatchModes[consume_int]

          # Ranking
          params[:rank_mode] = RankModes[consume_int]
          if params[:rank_mode] == :expr
            params[:rank_expr] = consume_string
          end

          # Sort Mode
          params[:sorting] = {
            mode: SortModes[consume_int],
            by: consume_string,
          }

          # Query
          params[:query] = consume_string

          # Weights
          params[:weights] = (1..consume_int).map { consume_int }

          # Index
          params[:index] = consume_string

          # ID Range
          consume_int
          params[:id_range] = consume_64int..consume_64int

          # Filters
          params[:filters] = (1..consume_int).map do
            attribute = consume_string
            type = FilterTypes[consume_int]
            values =
              case type
              when :values
                (1..consume_int).map { consume_64int }
              when :range
                consume_64int..consume_64int
              when :float_range
                consume_float..consume_float
              end
            exclude = consume_int
            {attribute: attribute, values: values, exclude: exclude}
          end

          # Grouping
          params[:group] = {
            function: GroupFunctions[consume_int],
            by: consume_string,
            max_matches: consume_int,
            clause: consume_string,
            retry: {cutoff: consume_int, count: consume_int, delay: consume_int},
            distinct: consume_string,
          }

          # Anchor Point
          if consume_int == 0
            params[:anchor] = nil
          else
            params[:anchor] = {
              attributes: [consume_string, consume_string],
              values: [consume_int, consume_int],
            }
          end

          # Per Index Weights
          per_index_weights = params[:per_index_weights] = {}
          (1..consume_int).each do |key, value|
            key = consume_string
            value = consume_int
            per_index_weights[key] = value
          end

          # Max Query Time
          params[:max_query_time] = consume_int

          # Per Field Weights
          per_field_weights = params[:per_field_weights] = {}
          (1..consume_int).each do |key, value|
            key = consume_string
            value = consume_int
            per_field_weights[key] = value
          end

          params[:comments] = consume_string

          return params if Riddle::Client::Versions[:search] < 0x116

          # Overrides
          overrides = params[:overrides] = {}
          (1..consume_int).each do
            key = consume_string
            type = AttributeTypes[consume_int]
            method =
              case type
              when :float
                :consume_float
              when :bigint
                :consume_64int
              else
                :consume_int
              end
            values = (1..consume_int).map { send(method) }
            overrides[key] = values
          end

          params[:select] = consume_string

          @m.empty? or
            params[:unknown] = @m

          params
        end

        def consume_int
          @m.slice!(0, 4).unpack("N").first
        end

        def consume_64int
          @m.slice!(0, 8).unpack("NN").first
        end

        def consume_float
          @m.slice!(0, 4).unpack('N').pack('L*').unpack('f').first
        end

        def consume_string
          @m.slice!(0, consume_int)
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
