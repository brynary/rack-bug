require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

class Rack::Bug
  describe LogPanel do
    before do
      LogPanel.reset
      rack_env "rack-bug.panel_classes", [LogPanel]
    end

    describe "heading" do
      it "displays 'Log'" do
        response = get_via_rack "/"
        response.should have_heading("Log")
      end
    end

    describe "content" do
      it "displays recorded log lines" do
        LogPanel.record("This is a logged message", 0)
        response = get_via_rack "/"
        response.should contain("This is a logged message")
        response.should contain("DEBUG")
      end
    end
  end
end
