module Insight
  describe MemoryPanel do
    before do
      rack_env "insight.panel_classes", [MemoryPanel]
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
