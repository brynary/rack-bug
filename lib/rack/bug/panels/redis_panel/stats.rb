module Rack
  module Bug
    class RedisPanel
      
      class Stats
        class Query
          attr_reader :time
          attr_reader :command
          attr_reader :backtrace
          
          def initialize(time, command_args, backtrace)
            @time = time
            @command = command_args.inspect
            @backtrace = backtrace
          end
          
          def display_time
            "%.2fms" % time
          end
          
          def has_backtrace?
            filtered_backtrace.any?
          end

          def filtered_backtrace
            @filtered_backtrace ||= @backtrace.map{|l| l.to_s.strip }.select do |line|
              !defined?(Rails) ||
              !Rails.respond_to?(:root) ||
              (line.starts_with?(Rails.root) && !line.starts_with?(Rails.root.join("vendor")))
            end
          end
        end
        
        attr_reader :calls
        attr_reader :queries
        
        def initialize
          @queries = []
          @calls = 0
          @time = 0.0
        end
        
        def record_call(time, command_args, backtrace)
          @queries << Query.new(time, command_args, backtrace)
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