require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

class Rack::Bug
  describe FiltersPanel do
    before do
      FiltersPanel.reset
      rack_env "rack-bug.panel_classes", [FiltersPanel]
    end

    describe "heading" do
      it "displays the total rendering time" do
        response = get_via_rack "/"
        response.should have_heading("Filters: 0.00ms")
      end
    end

    describe "content" do
      it "displays the filter paths" do
        FiltersPanel.record("some_filter") { }
        response = get_via_rack "/"
        response.should contain("some_filter")
      end
    end
  end
end
