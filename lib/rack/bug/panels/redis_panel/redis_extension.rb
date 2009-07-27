require 'redis'

if defined?(Redis)
  Redis.class_eval do

    def call_command_with_rack_bug(argv)
      Rack::Bug::RedisPanel.record(argv) do
        call_command_without_rack_bug(argv)
      end
    end
  
    alias_method_chain :call_command, :rack_bug
  end
end