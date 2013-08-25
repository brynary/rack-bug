require 'spec_helper'
require 'rack/insight/panels/rails_info_panel'

module Rack::Insight
  describe "RailsInfoPanel" do
    before do
      mock_constant("Rails::Info")
      reset_insight :panel_classes => [Rack::Insight::RailsInfoPanel]

      Rails::Info.stub(:properties => [])
    end

    describe "heading" do
      it "displays the Rails version" do
        Rails.stub(:version => "v2.3.0")
        response = get_via_rack "/"
        response.should have_heading("Rails v2.3.0")
      end
    end

    describe "content" do
      it "displays the Rails::Info properties" do
        Rails.stub(:version => "v2.3.0")
        Rails::Info.stub(:properties => [["CaptainKirkIs", "ClimbingTheMountain"]])
        response = get_via_rack "/"
        response.should have_row("#RailsInfoPanel", "CaptainKirkIs", "ClimbingTheMountain")
      end
    end
  end
end
