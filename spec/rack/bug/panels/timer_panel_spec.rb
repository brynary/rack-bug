require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

module Rack::Bug
  describe TimerPanel do
    before do
      header "rack-bug.panel_classes", [TimerPanel]
    end
    
    describe "heading" do
      it "displays the elapsed time" do
        response = get "/"
        response.should have_heading(TIME_MS_REGEXP)
      end
    end
    
    describe "content" do
      it "displays the user CPU time" do
        response = get "/"
        response.should have_row("#timer", "User CPU time", TIME_MS_REGEXP)
      end
      
      it "displays the system CPU time" do
        response = get "/"
        response.should have_row("#timer", "System CPU time", TIME_MS_REGEXP)
      end
      
      it "displays the total CPU time" do
        response = get "/"
        response.should have_row("#timer", "Total CPU time", TIME_MS_REGEXP)
      end
      
      it "displays the elapsed time" do
        response = get "/"
        response.should have_row("#timer", "Elapsed time", TIME_MS_REGEXP)
      end
    end
  end
end