require "rubygems"
require "sample_app"

$LOAD_PATH.unshift File.dirname(File.dirname(__FILE__)) + '/../../lib'
require "rack/bug"

use Rack::Bug, :password => "secret"
run SampleApp