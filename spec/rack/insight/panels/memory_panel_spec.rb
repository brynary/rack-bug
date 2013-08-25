require 'spec_helper'

module Rack::Insight
  describe "MemoryPanel" do
    before(:each) do
      reset_insight :panel => [Rack::Insight::MemoryPanel]
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
