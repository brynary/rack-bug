require 'riddle'

if defined?(Riddle)
  Riddle::Client.class_eval do
    def request_with_rack_bug(command, messages)
      Rack::Bug::SphinxPanel.record(command, messages) do
        request_without_rack_bug(command, messages)
      end
    end

    alias_method_chain :request, :rack_bug
  end
end
