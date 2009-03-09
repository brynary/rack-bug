require File.dirname(__FILE__) + '/../spec_helper'

describe Rack::Bug do
  
  def app
    Rack::Bug::Middleware.new(SampleApp.new)
  end
  
  def session
    @session ||= Rack::Test::Session.new(app)
  end
  
  def get(*args, &block)
    session.get(*args, &block)
  end
  
  def response
    session.last_response
  end
  
  it "should return the right Content-Length" do
    get "/"
    response["Content-Length"].should == response.body.join("\n").size.to_s
  end
  
  it "should track the elapsed time" do
    get "/"
    response.body.join("\n").should =~ /\d+\.\dms/
  end
  
end