require "rubygems"
require "spec"
require "rack/test"
require "webrat"

require File.dirname(__FILE__) + "/../lib/rack/bug"
require File.dirname(__FILE__) + "/fixtures/sample_app"

module Rails
  def self.version
    ""
  end
  
  class Info
    def self.properties
      []
    end
  end
end

Spec::Runner.configure do |config|
  TIME_MS_REGEXP = /\d+\.\d{2}ms/
  
  include Rack::Test::Methods
  include Webrat::Matchers
  
  def app
    Rack::Bug::Middleware.new(SampleApp.new)
  end
  
  def have_row(container, key, value = nil)
    simple_matcher("contain row") do |response|
      if value
        response.should have_selector("#{container} tr", :content => key) do |row|
          row.should contain(value)
        end
      else
        response.should have_selector("#{container} tr", :content => key)
      end
    end
  end
  
  def have_heading(text)
    simple_matcher("have heading") do |response|
      response.should have_selector("#rack_bug_toolbar li") do |heading|
        heading.should contain(text)
      end
    end
  end
end