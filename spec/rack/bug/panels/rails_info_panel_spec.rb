require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

class Rack::Bug
  describe RailsInfoPanel do
    before do
      rack_env "rack-bug.panel_classes", [RailsInfoPanel]
    end

    describe "heading" do
      it "displays the Rails version" do
        Rails.stub!(:version => "v2.3.0")
        response = get_via_rack "/"
        response.should have_heading("Rails v2.3.0")
      end
    end

    describe "content" do
      it "displays the Rails::Info properties" do
        Rails::Info.stub!(:properties => [["Name", "Value"]])
        response = get_via_rack "/"
        response.should have_row("#rails_info", "Name", "Value")
      end
    end
  end
end
