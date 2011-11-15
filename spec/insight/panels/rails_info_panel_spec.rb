module Insight
  describe RailsInfoPanel do
    before do
      mock_constant("Rails::Info")
      reset_insight :panel_classes => [RailsInfoPanel]

      Rails::Info.stub!(:properties => [])
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
        Rails.stub!(:version => "v2.3.0")
        Rails::Info.stub!(:properties => [["Name", "Value"]])
        response = get_via_rack "/"
        response.should have_row("#rails_info", "Name", "Value")
      end
    end
  end
end
