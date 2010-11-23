require 'redis'

if defined?(Redis)
  Redis.class_eval do
    if Redis.methods.include?('call_command') # older versions of redis-rb
      def call_command_with_rack_bug(*argv)
        Rack::Bug::RedisPanel.record(argv, Kernel.caller) do
          call_command_without_rack_bug(*argv)
        end
      end

      alias_method_chain :call_command, :rack_bug

    elsif defined?(Redis::Client) # newer versions of redis-rb

      Redis::Client.class_eval do
        def call_with_rack_bug(*argv)
          Rack::Bug::RedisPanel.record(argv, Kernel.caller) do
            call_without_rack_bug(*argv)
          end
        end

        alias_method_chain :call, :rack_bug

      end
    end
  end
end
