require 'spec_helper'
require 'rack/insight/panels/log_panel'

module Rack::Insight
  describe "LogPanel" do
    before do
      reset_insight :panel_classes => [Rack::Insight::LogPanel]
    end

    describe "heading" do
      it "displays 'Log'" do
        response = get_via_rack "/"
        response.should have_heading("Log")
      end
    end

    #describe "content" do
    #  it "displays recorded log lines" do
    #    Rack::Insight::Config.logger.fatal("This is a logged message")
    #    response = get_via_rack "/"
    #    response.should contain("This is a logged message")
    #    response.should contain("DEBUG")
    #  end
    #end

    describe "Extended Logger" do
      it "does still return true/false for #add if class Logger" do
        #AS::BufferedLogger returns the added string, Logger returns true/false
        LOGGER.add(0, "foo").should == true
      end
    end


    describe "With no logger defined" do
      it "does not err out" do
        logger = LOGGER
        Object.send :remove_const, :LOGGER
        lambda{ load("rack/insight/panels/log_panel.rb") }.should_not raise_error
        ::LOGGER = logger
      end
    end
  end
end
