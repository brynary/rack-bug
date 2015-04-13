require 'spec_helper'

describe Rack::Insight::EnableButton do

  context "request" do
    def app(*args)
      Rack::Builder.new do
        use Rack::Insight::EnableButton
        run lambda { |env| [200, {"Content-Type" => "text/html"}, ["<html><head></head><body><h1>Important</h1></body></html>"]] }
      end
    end

    it "inserts into the response" do
      response = Rack::MockRequest.new(app).get("/")
      expect(response.body).to eq %[<html><head></head><body><h1>Important</h1><script type="text/javascript" src='/__insight__/bookmarklet.js'></script>
<style>
  #rack-insight-enabler {
    position: absolute;
    z-index: 100000;
    overflow: hidden;
    width: 4px;
    height: 4px;
    top: 0;
    left: 0;
    background: #326342;
    color: #92EF3F;
  }

  #rack-insight-enabler:hover {
    width: auto;
    padding:5px;
    height: 24px;
  }
</style>

<a id='rack-insight-enabler' href="#" onclick="document.insightEnable()" style="">Rack::Insight</a>
</body></html>]
    end
  end
end
