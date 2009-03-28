require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

module Rack::Bug
  describe LogPanel do
    before do
      LogPanel.reset
      header "rack-bug.panel_classes", [LogPanel]
    end
    
    describe "heading" do
      it "displays 'Log'" do
        response = get "/"
        response.should have_heading("Log")
      end
    end
    
    describe "content" do
      it "displays recorded log lines" do
        LogPanel.record("This is a logged message")
        response = get "/"
        response.should contain("This is a logged message")
      end
    end
  end
end