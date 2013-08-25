require 'spec_helper'
require 'rack/insight/panels/redis_panel'

REDIS_INTERFACE = begin
  # When Redis::Client is defined then Redis >= 3.0.0
  if defined?(Redis::Client)
    {  client:  'Redis::Client',
       call_method: :call }
  elsif defined?(Redis)
    { client: 'Redis',
      call_method: :call_command }
  else
    nil
  end
end

module Rack::Insight
  describe "RedisPanel" do
    before do
      reset_insight :panel_classes => [Rack::Insight::RedisPanel]
    end

    describe "heading" do
      it "displays the total redis time" do
        response = get_via_rack "/"
        response.should have_heading("Redis: 0.00ms")
      end
    end

    describe "content" do
      describe "usage table" do
        it "displays the total number of redis calls" do
          Kernel.const_get(REDIS_INTERFACE[:client]).send(REDIS_INTERFACE[:call_method], ["get, user:1"])

          response = get_via_rack "/"

          # This causes a bus error:
          # response.should have_selector("th:content('Total Calls') + td", :content => "1")

          response.should have_row("#redis_usage", "Total Calls", "1")
        end

        it "displays the total redis time" do
          response = get_via_rack "/"
          response.should have_row("#redis_usage", "Total Time", "0.00ms")
        end
      end

      describe "breakdown" do
        it "displays each redis operation" do
          RedisPanel.record(["get, user:1"], Kernel.caller) { }
          response = get_via_rack "/"
          response.should have_row("#redis_breakdown", "get")
        end

        it "displays the time for redis call" do
          RedisPanel.record(["get, user:1"], Kernel.caller) { }
          response = get_via_rack "/"
          response.should have_row("#redis_breakdown", "user:1", TIME_MS_REGEXP)
        end

        it "displays the arguments for each redis call" do
          RedisPanel.record(["get, user:1"], Kernel.caller) { }
          response = get_via_rack "/"
          response.should have_row("#redis_breakdown", "user:1", "get")
        end

        it "displays a link to show the backtrace when it's available" do
          RedisPanel.record(["get, user:1"], Kernel.caller) { }
          response = get_via_rack "/"
          response.should have_row("#redis_breakdown", "user:1", "Show Backtrace")
        end

        it "does not display a link to show the backtrace when it's not available" do
          RedisPanel.record(["get, user:1"], []) { }
          response = get_via_rack "/"
          response.should_not contain("Show Backtrace")
        end
      end
    end
  end
end unless REDIS_INTERFACE.nil?
