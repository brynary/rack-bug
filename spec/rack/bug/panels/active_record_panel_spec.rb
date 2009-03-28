require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

module Rack::Bug
  describe ActiveRecordPanel do
    before do
      ActiveRecordPanel.reset
      header "rack-bug.panel_classes", [ActiveRecordPanel]
    end
    
    describe "heading" do
      it "displays the total number of instantiated AR objects" do
        ActiveRecordPanel.record("User")
        ActiveRecordPanel.record("Group")
        response = get "/"
        response.should have_heading("2 AR Objects")
      end
    end
    
    describe "content" do
      it "displays the count of instantiated objects for each class" do
        ActiveRecordPanel.record("User")
        ActiveRecordPanel.record("User")
        ActiveRecordPanel.record("Group")
        response = get "/"
        response.should have_row("#active_record", "User", "2")
        response.should have_row("#active_record", "Group", "1")
      end
    end
  end
end