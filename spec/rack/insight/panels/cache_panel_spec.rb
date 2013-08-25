require 'spec_helper'
require 'rack/insight/panels/cache_panel'

module Rack::Insight
  describe "CachePanel" do
    before do
      mock_constant("Rails")
      mock_constant("Memcached")
      mock_constant("MemCache")
      reset_insight :panel_classes => [Rack::Insight::CachePanel]
    end

    describe "heading" do
      it "displays the total memcache time" do
        response = get_via_rack "/"
        response.should have_heading("Cache: 0.00ms")
      end
    end

    describe "content" do
      describe "usage table" do
        it "displays the total number of memcache calls" do
          app.before_return do
            mock_method_call("Memcached", "get", ["user:1"])
          end
          response = get_via_rack "/"

          # This causes a bus error:
          # response.should have_selector("th:content('Total Calls') + td", :content => "1")

          response.should have_row("#cache_usage", "Total Calls", "1")
        end

        it "displays the total memcache time" do
          response = get_via_rack "/"
          response.should have_row("#cache_usage", "Total Time", "0.00ms")
        end

        it "dispays the number of memcache hits" do
          app.before_return do
            mock_method_call("Memcached", "get", ["user:1"])
          end
          response = get_via_rack "/"
          response.should have_row("#cache_usage", "Hits", "0")
        end

        it "displays the number of memcache misses" do
          app.before_return do
            mock_method_call("Memcached", "get", ["user:1"])
          end
          response = get_via_rack "/"
          response.should have_row("#cache_usage", "Misses", "1")
        end

        it "displays the number of memcache gets" do
          app.before_return do
            mock_method_call("Memcached", "get", ["user:1"])
          end
          response = get_via_rack "/"
          response.should have_row("#cache_usage", "gets", "1")
        end

        it "displays the number of memcache sets" do

          app.before_return do
            mock_method_call("Memcached", "set", ["user:1"])
          end
          response = get_via_rack "/"
          response.should have_row("#cache_usage", "sets", "1")
        end

        it "displays the number of memcache deletes" do
          app.before_return do
            mock_method_call("Memcached", "delete", ["user:1"])
          end
          response = get_via_rack "/"
          response.should have_row("#cache_usage", "deletes", "1")
        end

        it "displays the number of memcache get_multis" do
          app.before_return do
            mock_method_call("MemCache", "get_multi", ["user:1", "user:2"])
          end
          response = get_via_rack "/"
          response.should have_row("#cache_usage", "get_multis", "1")
        end
      end

      describe "breakdown" do
        it "displays each memcache operation" do
          app.before_return do
            mock_method_call("Memcached", "get", ["user:1"])
          end
          response = get_via_rack "/"
          response.should have_row("#cache_breakdown", "get")
        end

        it "displays the time for each memcache call" do
          app.before_return do
            mock_method_call("Memcached", "get", ["user:1"])
          end
          response = get_via_rack "/"
          response.should have_row("#cache_breakdown", "user:1", TIME_MS_REGEXP)
        end

        it "displays the keys for each memcache call" do
          app.before_return do
            mock_method_call("Memcached", "get", ["user:1"])
          end
          response = get_via_rack "/"
          response.should have_row("#cache_breakdown", "user:1", "get")
        end
      end
    end

    describe "cache operations" do
      before do
        app.insight_app.secret_key = 'abc'
        response = get_via_rack "/"
      end


      describe "expire_all" do
        it "expires the cache keys" do
          Rails.stub(:cache => double("cache"))
          Rails.cache.should_receive(:delete).with("user:1")
          Rails.cache.should_receive(:delete).with("user:2")
          Rails.cache.should_receive(:delete).with("user:3")
          Rails.cache.should_receive(:delete).with("user:4")

          get_via_rack "/__insight__/delete_cache_list",
            :keys_1 => "user:1", :keys_2 => "user:2", :keys_3 => "user:3", :keys_4 => "user:4",
            :hash => Digest::SHA1.hexdigest("abc:user:1:user:2:user:3:user:4")
        end

        it "returns OK" do
          Rails.stub(:cache => double("cache", :delete => nil))
          response = get_via_rack "/__insight__/delete_cache_list",
            :keys_1 => "user:1", :keys_2 => "user:2", :keys_3 => "user:3", :keys_4 => "user:4",
            :hash => Digest::SHA1.hexdigest("abc:user:1:user:2:user:3:user:4")
          response.should contain("OK")
        end
      end

      describe "expire" do
        it "expires the cache key" do
          Rails.stub(:cache => double("cache"))
          Rails.cache.should_receive(:delete).with("user:1")
          get_via_rack "/__insight__/delete_cache", :key => "user:1",
            :hash => Digest::SHA1.hexdigest("abc:user:1")
        end

        it "returns OK" do
          Rails.stub(:cache => double("cache", :delete => nil))
          response = get_via_rack "/__insight__/delete_cache", :key => "user:1",
            :hash => Digest::SHA1.hexdigest("abc:user:1")
          response.should contain("OK")
        end
      end

      describe "view_cache" do
        it "renders the cache key" do
          Rails.stub(:cache => double("cache", :read => "cache body"))
          response = get_via_rack "/__insight__/view_cache", :key => "user:1",
            :hash => Digest::SHA1.hexdigest("abc:user:1")
          response.should contain("cache body")
        end

        it "renders non-String cache values properly" do
          Rails.stub(:cache => double("cache", :read => [1, 2]))
          response = get_via_rack "/__insight__/view_cache", :key => "user:1",
            :hash => Digest::SHA1.hexdigest("abc:user:1")
          response.should contain("[1, 2]")
        end
      end

    end
  end
end
