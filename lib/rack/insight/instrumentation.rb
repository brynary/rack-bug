module Rack::Insight
  module Instrumentation; end
end
require 'rack/insight/instrumentation/instrument'
require 'rack/insight/instrumentation/probe'
require 'rack/insight/instrumentation/client'
require 'rack/insight/instrumentation/eigen_client'
require 'rack/insight/instrumentation/setup'
require 'rack/insight/instrumentation/package-definition'
require 'rack/insight/instrumentation/probe-definition'
