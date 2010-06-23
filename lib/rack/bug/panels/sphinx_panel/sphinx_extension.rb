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

if defined?(Sphinx::Client)
  Sphinx::Client.class_eval do
    def PerformRequest_with_rack_bug(command, request, additional = nil)
      Rack::Bug::SphinxPanel.record(command, request) do
        PerformRequest_without_rack_bug(command, request, additional)
      end
    end

    alias_method_chain :PerformRequest, :rack_bug
  end
end
