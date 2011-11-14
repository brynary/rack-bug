if defined?(Riddle)
  Riddle::Client.class_eval do
    def request_with_insight(command, messages)
      Insight::SphinxPanel.record(command, messages) do
        request_without_insight(command, messages)
      end
    end

    alias_method_chain :request, :insight
  end
end

if defined?(Sphinx::Client)
  Sphinx::Client.class_eval do
    def PerformRequest_with_insight(command, request, additional = nil)
    end
  end

  alias_method_chain :PerformRequest, :insight
end
