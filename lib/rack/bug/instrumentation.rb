class Rack::Bug
  module Instrumentation; end
end

require 'rack/bug/instrumentation/instrument'
require 'rack/bug/instrumentation/probe'
require 'rack/bug/instrumentation/client'
require 'rack/bug/instrumentation/setup'
require 'rack/bug/instrumentation/package-definition'
require 'rack/bug/instrumentation/probe-definition'
