require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module Rack::Bug
  describe SQLPanel do
    before do
      SQLPanel.reset
    end
    
    describe "heading" do
      it "displays the total SQL query count" do
        SQLPanel.record("SELECT NOW();") { }
        response = get "/"
        response.should have_heading("1 Queries")
      end
      
      it "displays the total SQL time" do
        SQLPanel.record("SELECT NOW();") { }
        response = get "/"
        response.should have_heading(/Queries \(\d+\.\d{2}ms\)/)
      end
    end
    
    describe "content" do
      it "displays each executed SQL query" do
        SQLPanel.record("SELECT NOW();") { }
        response = get "/"
        response.should have_row("#sql", "SELECT NOW();")
      end
      
      it "displays the time of each executed SQL query" do
        SQLPanel.record("SELECT NOW();") { }
        response = get "/"
        response.should have_row("#sql", "SELECT NOW();", TIME_MS_REGEXP)
      end
    end
  end
end