require "rubygems"

$LOAD_PATH.unshift File.dirname(__FILE__)
require "sample_app"

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'
require "rack/bug"

use Rack::Bug, :password => "secret"
run SampleApp