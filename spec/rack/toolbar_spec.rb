require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Rack::Bug do
  it "inserts the Rack::Bug toolbar" do
    response = get "/"
    response.should have_selector("div#rack_bug")
  end
  
  it "updates the Content-Length" do
    response = get "/"
    response["Content-Length"].should == response.body.size.to_s
  end
  
  it "serves the Rack::Bug assets under /__rack_bug__/" do
    response = get "/__rack_bug__/bug.css"
    response.should be_ok
  end
  
  it "modifies HTML responses with a charset" do
    response = get "/", :content_type => "application/xhtml+xml; charset=utf-8"
    response.should have_selector("div#rack_bug")
  end
  
  it "does not modify XMLHttpRequest responses" do
    response = get "/", {}, { :xhr => true }
    response.should_not have_selector("div#rack_bug")
  end
  
  it "modifies XHTML responses" do
    response = get "/", :content_type => "application/xhtml+xml"
    response.should have_selector("div#rack_bug")
  end
  
  it "does not modify non-HTML responses" do
    response = get "/", :content_type => "text/csv"
    response.should_not have_selector("div#rack_bug")
  end

  it "does not modify redirects" do
    response = get "/redirect"
    response.body.should == ""
  end
  
  it "does not modify server errors" do
    response = get "/error"
    response.should_not have_selector("div#rack_bug")
  end
  
  context "configured to intercept redirects" do
    it "inserts the Rack::Bug toolbar for redirects" do
      response = get "/redirect", {}, "rack-bug.intercept_redirects" => true
      response.should contain("Location: /")
    end
  end
  
  context "configured with an IP address restriction" do
    before do
      header "rack-bug.ip_masks", [IPAddr.new("127.0.0.1/255.255.255.0")]
    end
    
    it "inserts the Rack::Bug toolbar when the IP matches" do
      response = get "/", {}, "REMOTE_ADDR" => "127.0.0.2"
      response.should have_selector("div#rack_bug")
    end
    
    it "is disabled when the IP doesn't match" do
      response = get "/", {}, "REMOTE_ADDR" => "128.0.0.1"
      response.should_not have_selector("div#rack_bug")
    end
    
    it "doesn't use any panels" do
      DummyPanel.should_not_receive(:new)
      header "rack-bug.panel_classes", [DummyPanel]
      get "/", {}, "REMOTE_ADDR" => "128.0.0.1"
    end
  end
  
  context "configured with a password" do
    before do
      header "rack-bug.password", "secret"
    end
    
    it "inserts the Rack::Bug toolbar when the password matches" do
      sha = "545049d1c5e2a6e0dfefd37f9a9e0beb95241935"
      response = get "/", {}, :cookie => ["rack_bug_enabled=1", "rack_bug_password=#{sha}"]
      response.should have_selector("div#rack_bug")
    end
    
    it "is disabled when the password doesn't match" do
      response = get "/"
      response.should_not have_selector("div#rack_bug")
    end
    
    it "doesn't use any panels" do
      DummyPanel.should_not_receive(:new)
      header "rack-bug.panel_classes", [DummyPanel]
      get "/"
    end
  end
end