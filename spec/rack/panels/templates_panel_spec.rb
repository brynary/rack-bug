require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module Rack::Bug
  describe TemplatesPanel do
    describe "heading" do
      it "displays the total rendering time"
    end
    
    describe "content" do
      it "displays the template paths"
      it "displays the template children"
      
      context "for templates that rendered templates" do
        it "displays the total time"
        it "displays the exclusive time"
      end
      
      context "for leaf templates" do
        it "does not display the exclusive time"
      end
    end
  end
end