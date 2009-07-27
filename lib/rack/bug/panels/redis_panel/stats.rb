module Rack
  module Bug
    class RedisPanel
      
      class Stats
        class Query
          attr_reader :time
          attr_reader :command
          
          def initialize(time, *command_args)
            @time = time
            @command = command_args.inspect
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
        
        def record_call(time, *command_args)
          @queries << Query.new(time, command_args)
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
end