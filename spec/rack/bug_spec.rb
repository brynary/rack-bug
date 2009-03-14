require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Rack::Bug do
  it "inserts the Rack::Bug toolbar" do
    response = get "/"
    response.should contain("Rack::Bug")
  end
  
  it "updates the Content-Length" do
    response = get "/"
    response["Content-Length"].should == response.body.join.size.to_s
  end
  
  it "serves the Rack::Bug assets under /__rack_bug__/" do
    response = get "/__rack_bug__/bug.css"
    response.should be_ok
  end
  
  it "does not modify XMLHttpRequest responses" do
    response = get "/", {}, { :xhr => true }
    response.should_not contain("Rack::Bug")
  end
  
  it "modifies XHHTML responses" do
    response = get "/", :content_type => "application/xhtml+xml"
    response.should contain("Rack::Bug")
  end
  
  it "does not modify non-HTML responses" do
    response = get "/", :content_type => "text/csv"
    response.should_not contain("Rack::Bug")
  end
  
  it "does not modify server errors" do
    response = get "/error"
    response.should_not contain("Rack::Bug")
  end
end