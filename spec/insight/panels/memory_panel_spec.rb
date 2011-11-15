module Insight
  describe MemoryPanel do
    before do
      reset_insight :panel => [MemoryPanel]
    end

    describe "heading" do
      it "displays the total memory" do
        response = get_via_rack "/"
        response.should have_heading(/\d+ KB total/)
      end

      it "displays the memory change during the request" do
        response = get_via_rack "/"
        response.should have_heading(/\d+ KB/)
      end
    end
  end
end
