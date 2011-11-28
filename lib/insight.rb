module Insight
  class << self
    def enable
      Thread.current["insight.enabled"] = true
    end

    def disable
      Thread.current["insight.enabled"] = false
    end

    def enabled?
      Thread.current["insight.enabled"] == true
    end
  end
end

require 'insight/app'
