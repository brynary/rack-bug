if defined?(MemCache)
  MemCache.class_eval do

    def decr_with_rack_test(key, amount = 1)
      Rack::Bug::CachePanel.record(:decr, key) do
        decr_without_rack_test(key, amount)
      end
    end

    def get_with_rack_test(key, raw = false)
      Rack::Bug::CachePanel.record(:get, key) do
        get_without_rack_test(key, raw)
      end
    end

    def get_multi_with_rack_test(*keys)
      Rack::Bug::CachePanel.record(:get_multi, *keys) do
        get_multi_without_rack_test(*keys)
      end
    end

    def incr_with_rack_test(key, amount = 1)
      Rack::Bug::CachePanel.record(:incr, key) do
        incr_without_rack_test(key, amount)
      end
    end

    def set_with_rack_test(key, value, expiry = 0, raw = false)
      Rack::Bug::CachePanel.record(:set, key) do
        set_without_rack_test(key, value, expiry, raw)
      end
    end

    def add_with_rack_test(key, value, expiry = 0, raw = false)
      Rack::Bug::CachePanel.record(:add, key) do
        add_without_rack_test(key, value, expiry, raw)
      end
    end

    def delete_with_rack_test(key, expiry = 0)
      Rack::Bug::CachePanel.record(:delete, key) do
        delete_without_rack_test(key, expiry)
      end
    end
    
    alias_method_chain :decr,       :rack_test
    alias_method_chain :get,        :rack_test
    alias_method_chain :get_multi,  :rack_test
    alias_method_chain :incr,       :rack_test
    alias_method_chain :set,        :rack_test
    alias_method_chain :add,        :rack_test
    alias_method_chain :delete,     :rack_test
  end
end