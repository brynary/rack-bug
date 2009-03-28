require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

module Rack::Bug
  describe EnvPanel do
    before do
      header "rack-bug.panel_classes", [EnvPanel]
    end
    
    describe "heading" do
      it "displays 'Rack Env'" do
        response = get "/"
        response.should have_heading("Rack Env")
      end
    end
    
    describe "content" do
      it "displays the Rack environment" do
        response = get "/"
        response.should have_row("#env", "PATH_INFO", "/")
        response.should have_row("#env", "REMOTE_ADDR", "127.0.0.1")
      end
    end
  end
end