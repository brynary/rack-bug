require 'spec_helper'

describe Rack::Insight do
  before :each do
    reset_insight
  end

  it "inserts the Rack::Insight toolbar" do
    response = get "/"
    response.should have_selector("div#rack-insight")
  end

  it "updates the Content-Length" do
    response = get "/"
    response["Content-Length"].should == response.body.size.to_s
  end

  it "serves the Rack::Insight assets under /__insight__/" do
    response = get "/__insight__/insight.css"
    response.should be_ok
  end

  it "modifies HTML responses with a charset" do
    response = get "/", :content_type => "application/xhtml+xml; charset=utf-8"
    response.should have_selector("div#rack-insight")
  end

  it "does not modify XMLHttpRequest responses" do
    response = get "/", {}, { :xhr => true }
    response.should_not have_selector("div#rack-insight")
  end

  it "modifies XHTML responses" do
    response = get "/", :content_type => "application/xhtml+xml"
    response.should have_selector("div#rack-insight")
  end

  it "does not modify non-HTML responses" do
    response = get "/", :content_type => "text/csv"
    response.should_not have_selector("div#rack-insight")
  end

  it "does not modify server errors" do
    app.disable :raise_errors
    response = get "/error"
    app.enable :raise_errors
    response.should_not have_selector("div#rack-insight")
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
      response.should_not have_selector("div#rack-insight")
    end

    it "does not insert the toolbar if even toolbar requested" do
      response = get "/redirect"
      response.should_not have_selector("div#rack-insight")
    end
  end

  context "redirected when configured to intercept redirects" do
    before :each do
      app.insight_app.intercept_redirects = true
    end

    it "shows the interception page" do
      response = get "/redirect"
      response.should have_selector("div#rack-insight")
    end

    it "should provide a link to the target URL" do
      response = get "/redirect"
      response.should have_selector("a[href='http://example.org/']")
    end

    it "inserts the toolbar if requested" do
      response = get "/redirect"
      response.should have_selector("div#rack-insight")
    end

    it "does not inserts the toolbar if not requested" do
      header 'cookie', ""
      response = get "/redirect"
      response.should_not have_selector("div#rack-insight")
    end
  end

  context "configured with an IP address restriction" do
    before do
      app.insight_app.ip_masks = [IPAddr.new("127.0.0.1/255.255.255.0")]
    end

    it "inserts the Rack::Insight toolbar when the IP matches" do
      response = get_via_rack "/", {}, "REMOTE_ADDR" => "127.0.0.2"
      response.should have_selector("div#rack-insight")
    end

    it "is disabled when the IP doesn't match" do
      response = get_via_rack "/", {}, "REMOTE_ADDR" => "128.0.0.1"
      response.should_not have_selector("div#rack-insight")
    end

    it "doesn't use any panels" do
      DummyPanel.should_not_receive(:new)
      app.insight_app.panel_classes = [DummyPanel]
      get_via_rack "/", {}, "REMOTE_ADDR" => "128.0.0.1"
    end
  end

  context "configured with a password" do
    before do
      app.insight_app.password = "secret"
    end

    it "should insert the Rack::Insight toolbar when the password matches" do
      sha = Digest::SHA1.hexdigest ["rack-insight", "secret"].join(":")
      set_cookie ["rack-insight_enabled=1", "rack-insight_password=#{sha}"]
      response = get_via_rack "/"
      response.should have_selector("div#rack-insight")
    end

    it "should be disabled when the password doesn't match" do
      response = get_via_rack "/"
      response.should_not have_selector("div#rack-insight")
    end
    it "doesn't use any panels" do
      DummyPanel.should_not_receive(:new)
      app.insight_app.panel_classes = [DummyPanel]
      get_via_rack "/"
    end
  end

  # These specs are no longer applicable, since reset_insight no longer clears the sqlite database.
  # Clearing of the database is now accomplished in a *config.after :suite do* block

  #context "configured with a SQLite database file path" do
  #  before do
  #    # We need to pass the SQLite database file path to the gem
  #    require 'fileutils'
  #    FileUtils.rm_rf("my_custom_db_path.sqlite") #because it doesn't count if it's already there
  #    reset_insight :database_path => 'my_custom_db_path.sqlite'
  #  end
  #
  #  it "should create a database at the path specified in the options" do
  #    File.exist?('my_custom_db_path.sqlite').should be_true
  #  end
  #
  #  after do
  #    FileUtils.rm_rf("my_custom_db_path.sqlite")
  #    reset_insight :database_path => nil
  #  end
  #
  #end
end
