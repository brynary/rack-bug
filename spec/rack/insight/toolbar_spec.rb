require 'spec_helper'

describe Rack::Insight::Toolbar do

  context "request" do

    def toolbar_app(*args)
      Rack::Builder.new do
        use Rack::Insight::Toolbar, Rack::Insight::App.new(self)
        run lambda { |env| [200, {"Content-Type" => "text/html"}, ["<html><head></head><body><h1>Important</h1></body></html>"]] }
      end
    end

    it "inserts into the response" do
      response = Rack::MockRequest.new(toolbar_app).get("/")
      expect(response.body).to match /<div id="rack-insight_debug_window" class="panel_content"><\/div>/
    end
  end
end
