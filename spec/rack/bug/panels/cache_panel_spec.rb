require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

module Rack::Bug
  describe CachePanel do
    before do
      CachePanel.reset
      header "rack-bug.panel_classes", [CachePanel]
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
    
    describe "expire_all" do
      it "expires the cache keys" do
        Rails.stub!(:cache => mock("cache"))
        Rails.cache.should_receive(:delete).with("user:1")
        Rails.cache.should_receive(:delete).with("user:2")
        Rails.cache.should_receive(:delete).with("user:3")
        Rails.cache.should_receive(:delete).with("user:4")
        get "/__rack_bug__/delete_cache_list", :keys => {"1" => "user:1", "2" => "user:2", "3" => "user:3", "4" => "user:4"}
      end
      
      it "returns OK" do
        Rails.stub!(:cache => mock("cache", :delete => nil))
        response = get "/__rack_bug__/delete_cache_list", :keys => {"1" => "user:1", "2" => "user:2", "3" => "user:3", "4" => "user:4"}
        response.should contain("OK")
      end
    end
    
    describe "expire" do
      it "expires the cache key" do
        Rails.stub!(:cache => mock("cache"))
        Rails.cache.should_receive(:delete).with("user:1")
        get "/__rack_bug__/delete_cache", :key => "user:1"
      end
      
      it "returns OK" do
        Rails.stub!(:cache => mock("cache", :delete => nil))
        response = get "/__rack_bug__/delete_cache", :key => "user:1"
        response.should contain("OK")
      end
    end
    
    describe "view_cache" do
      it "renders the cache key" do
        Rails.stub!(:cache => mock("cache", :read => "cache body"))
        response = get "/__rack_bug__/view_cache", :key => "user:1"
        response.should contain("cache body")
      end
      
      it "renders non-String cache values properly" do
        Rails.stub!(:cache => mock("cache", :read => [1, 2]))
        response = get "/__rack_bug__/view_cache", :key => "user:1"
        response.should contain("[1, 2]")
      end
    end

  end
end