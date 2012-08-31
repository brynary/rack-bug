require 'spec_helper'

describe Rack::Insight::Config do

  context "configured with panel_load_paths" do
    before(:each) do
      Rack::Insight::Config.configure do |config|
        # spec folder is in the load path during specs!
        config[:panel_load_paths] << 'fixtures'
      end
      require 'fixtures/star_trek_panel'
      reset_insight :panel_files => %w{star_trek_panel}
    end
    it "should use StarTrekPanel" do
      app.insight_app.panel_classes.include?(StarTrekPanel).should be_true
      #get_via_rack "/"
      response = get "/", :content_type => "application/xhtml+xml"
      response.should have_selector("table#StarTrek", :content => 'Enterprise')
    end
  end

end
