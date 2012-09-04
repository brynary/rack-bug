require 'logger'
require 'rack/insight/app'

module Rack
  module Insight
    class << self

      include Logging

      def enable
        Thread.current["rack-insight.enabled"] = true
      end

      def disable
        Thread.current["rack-insight.enabled"] = false
      end

      def enabled?
        Thread.current["rack-insight.enabled"] == true
      end
    end
  end
end
