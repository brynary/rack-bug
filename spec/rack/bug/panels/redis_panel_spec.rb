require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
$LOADED_FEATURES << "redis.rb" #avoid dependency on redis

module Rack::Bug
  describe RedisPanel do
    before do
      RedisPanel.reset
      header "rack-bug.panel_classes", [RedisPanel]
    end
    
    describe "heading" do
      it "displays the total redis time" do
        response = get "/"
        response.should have_heading("Redis: 0.00ms")
      end
    end
    
    describe "content" do
      describe "usage table" do
        it "displays the total number of redis calls" do
          RedisPanel.record(["get, user:1"]) { }
          response = get "/"
          
          # This causes a bus error:
          # response.should have_selector("th:content('Total Calls') + td", :content => "1")

          response.should have_row("#redis_usage", "Total Calls", "1")
        end
        
        it "displays the total redis time" do
          response = get "/"
          response.should have_row("#redis_usage", "Total Time", "0.00ms")
        end
      end
      
      describe "breakdown" do
        it "displays each redis operation" do
          RedisPanel.record(["get, user:1"]) { }
          response = get "/"
          response.should have_row("#redis_breakdown", "get")
        end
        
        it "displays the time for redis call" do
          RedisPanel.record(["get, user:1"]) { }
          response = get "/"
          response.should have_row("#redis_breakdown", "user:1", TIME_MS_REGEXP)
        end
        
        it "displays the arguments for each redis call" do
          RedisPanel.record(["get, user:1"]) { }
          response = get "/"
          response.should have_row("#redis_breakdown", "user:1", "get")
        end
      end
    end
  end
end