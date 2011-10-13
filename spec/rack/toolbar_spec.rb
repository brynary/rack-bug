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

  it "does not modify server errors" do
    response = get "/error"
    response.should_not have_selector("div#rack_bug")
  end

  context "redirected when not configured to intercept redirects" do
    it "passes the redirect unmodified" do
      response = get "/redirect"
      response.status.should == 302
    end
    
    it "does not show the interception page" do
      response = get "/redirect"
      response.body.should_not contain("Location: /")
    end

    it "does not insert the toolbar" do
      header 'cookie', ""
      response = get "/redirect"
      response.should_not have_selector("div#rack_bug")
     end
    
    it "does not insert the toolbar if even toolbar requested" do
      response = get "/redirect"
      response.should_not have_selector("div#rack_bug")
     end
  end
  
  context "redirected when configured to intercept redirects" do
    it "shows the interception page" do
      response = get "/redirect", {}, "rack-bug.intercept_redirects" => true
      response.should have_selector("div#rack_bug")
    end

    it "should provide a link to the target URL" do
      pending do # broken after adding Gemfile -> worked with an old version of one of the gems
        response = get "/redirect", {}, "rack-bug.intercept_redirects" => true
        response.should have_selector("a[href='/']")
      end
    end
    
    it "inserts the toolbar if requested" do
      response = get "/redirect", {}, "rack-bug.intercept_redirects" => true
      response.should have_selector("div#rack_bug")
    end
    
    it "does not inserts the toolbar if not requested" do
      header 'cookie', ""
      response = get "/redirect", {}, "rack-bug.intercept_redirects" => true
      response.should_not have_selector("div#rack_bug")
    end
  end

  context "configured with an IP address restriction" do
    before do
      rack_env "rack-bug.ip_masks", [IPAddr.new("127.0.0.1/255.255.255.0")]
    end

    it "inserts the Rack::Bug toolbar when the IP matches" do
      response = get_via_rack "/", {}, "REMOTE_ADDR" => "127.0.0.2"
      response.should have_selector("div#rack_bug")
    end

    it "is disabled when the IP doesn't match" do
      response = get_via_rack "/", {}, "REMOTE_ADDR" => "128.0.0.1"
      response.should_not have_selector("div#rack_bug")
    end

    it "doesn't use any panels" do
      DummyPanel.should_not_receive(:new)
      rack_env "rack-bug.panel_classes", [DummyPanel]
      get_via_rack "/", {}, "REMOTE_ADDR" => "128.0.0.1"
    end
  end

  context "configured with a password" do
    before do
      rack_env "rack-bug.password", "secret"
    end

    it "inserts the Rack::Bug toolbar when the password matches" do
      sha = "545049d1c5e2a6e0dfefd37f9a9e0beb95241935"
      set_cookie ["rack_bug_enabled=1", "rack_bug_password=#{sha}"]
      response = get_via_rack "/"
      response.should have_selector("div#rack_bug")
    end

    it "is disabled when the password doesn't match" do
      response = get_via_rack "/"
      response.should_not have_selector("div#rack_bug")
    end

    it "doesn't use any panels" do
      DummyPanel.should_not_receive(:new)
      rack_env "rack-bug.panel_classes", [DummyPanel]
      get_via_rack "/"
    end
  end
end
