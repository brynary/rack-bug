require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Rack::Bug do
  it "should return the correct Content-Length" do
    response = get "/"
    response["Content-Length"].should == response.body.join.size.to_s
  end
end