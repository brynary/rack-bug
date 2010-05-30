require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

class Rack::Bug
  describe MemoryPanel do
    before do
      rack_env "rack-bug.panel_classes", [MemoryPanel]
    end

    describe "heading" do
      it "displays the total memory" do
        response = get_via_rack "/"
        response.should have_heading(/\d+ KB total/)
      end

      it "displays the memory change during the request" do
        response = get_via_rack "/"
        response.should have_heading(/\d+ KB Δ/)
      end
    end
  end
end
