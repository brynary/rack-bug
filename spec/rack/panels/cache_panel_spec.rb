require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module Rack::Bug
  describe CachePanel do
    before do
      CachePanel.reset
    end
    
    describe "heading" do
      it "displays the total memcache time" do
        response = get "/"
        response.should have_heading("Cache: 0.00ms")
      end
    end
    
    describe "content" do
      describe "usage table" do
        it "displays the total number of memcache calls" do
          CachePanel.record(:get, "user:1") { }
          response = get "/"
          
          # This causes a bus error:
          # response.should have_selector("th:content('Total Calls') + td", :content => "1")

          response.should have_row("#cache_usage", "Total Calls", "1")
        end
        
        it "displays the total memcache time" do
          response = get "/"
          response.should have_row("#cache_usage", "Total Time", "0.00ms")
        end
        
        it "dispays the number of memcache hits" do
          CachePanel.record(:get, "user:1") { }
          response = get "/"
          response.should have_row("#cache_usage", "Hits", "0")
        end
        
        it "displays the number of memcache misses" do
          CachePanel.record(:get, "user:1") { }
          response = get "/"
          response.should have_row("#cache_usage", "Misses", "1")
        end
        
        it "displays the number of memcache gets" do
          CachePanel.record(:get, "user:1") { }
          response = get "/"
          response.should have_row("#cache_usage", "gets", "1")
        end
        
        it "displays the number of memcache sets" do
          CachePanel.record(:set, "user:1") { }
          response = get "/"
          response.should have_row("#cache_usage", "sets", "1")
        end
        
        it "displays the number of memcache deletes" do
          CachePanel.record(:delete, "user:1") { }
          response = get "/"
          response.should have_row("#cache_usage", "deletes", "1")
        end
        
        it "displays the number of memcache get_multis" do
          CachePanel.record(:get_multi, "user:1", "user:2") { }
          response = get "/"
          response.should have_row("#cache_usage", "get_multis", "1")
        end
      end
      
      describe "breakdown" do
        it "displays each memcache operation" do
          CachePanel.record(:get, "user:1") { }
          response = get "/"
          response.should have_row("#cache_breakdown", "get")
        end
        
        it "displays the time for each memcache call" do
          CachePanel.record(:get, "user:1") { }
          response = get "/"
          response.should have_row("#cache_breakdown", "user:1", TIME_MS_REGEXP)
        end
        
        it "displays the keys for each memcache call" do
          CachePanel.record(:get, "user:1") { }
          response = get "/"
          response.should have_row("#cache_breakdown", "user:1", "get")
        end
      end
    end
  end
end