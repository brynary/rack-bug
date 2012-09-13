if defined?(Redis)
  Redis.class_eval do
    if Redis.methods.include?('call_command') # older versions of redis-rb
      def call_command_with_insight(*argv)
        Rack::Insight::RedisPanel.record(argv, Kernel.caller) do
          call_command_without_insight(*argv)
        end
      end

      alias_method_chain :call_command, :insight

    elsif defined?(Redis::Client) # newer versions of redis-rb

      Redis::Client.class_eval do
        def call_with_insight(*argv)
        end
      end

      Redis::Client.alias_method_chain :call, :insight
    end
  end
end
