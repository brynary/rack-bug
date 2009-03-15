require "rubygems"
require "sample_app"
require File.dirname(__FILE__) + "/../../lib/rack/bug"

use Rack::Bug, :password => "secret"
run SampleApp