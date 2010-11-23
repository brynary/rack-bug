require "rubygems"

$LOAD_PATH.unshift File.dirname(__FILE__)
require "sample_app"

#Example usage, but moved inside sample app for easier testing
#use Rack::Bug, :password => "secret"
run SampleApp