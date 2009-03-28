require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

module Rack::Bug
  describe TemplatesPanel do
    before do
      TemplatesPanel.reset
      header "rack-bug.panel_classes", [TemplatesPanel]
    end
    
    describe "heading" do
      it "displays the total rendering time" do
        response = get "/"
        response.should have_heading("Templates: 0.00ms")
      end
    end
    
    describe "content" do
      it "displays the template paths" do
        TemplatesPanel.record("users/show") { }
        response = get "/"
        response.should contain("users/show")
      end
      
      it "displays the template children" do
        TemplatesPanel.record("users/show") do
          TemplatesPanel.record("users/toolbar") { }
        end
        
        response = get "/"
        response.should have_selector("li", :content => "users/show") do |li|
          li.should contain("users/toolbar")
        end
      end
      
      context "for templates that rendered templates" do
        it "displays the total time" do
          TemplatesPanel.record("users/show") do
            TemplatesPanel.record("users/toolbar") { }
          end
          
          response = get "/"
          response.should have_selector("li", :content => "users/show") do |li|
            li.should contain(TIME_MS_REGEXP)
          end
        end
        
        it "displays the exclusive time" do
          TemplatesPanel.record("users/show") do
            TemplatesPanel.record("users/toolbar") { }
          end
          
          response = get "/"
          response.should have_selector("li", :content => "users/show") do |li|
            li.should contain(/\d\.\d{2} exclusive/)
          end
        end
      end
      
      context "for leaf templates" do
        it "does not display the exclusive time" do
          TemplatesPanel.record("users/show") { }
          
          response = get "/"
          response.should contain("users/show") do |li|
            li.should_not contain("exclusive")
          end
        end
      end
    end
  end
end