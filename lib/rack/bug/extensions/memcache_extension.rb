if defined?(Memcached)
  Memcached.class_eval do

    def set_with_rack_bug(key, value, timeout=0, marshal=true)
      Rack::Bug::CachePanel.record(:set, key) do
        set_without_rack_bug(key, value, timeout, marshal)
      end
    end

    def add_with_rack_bug(key, value, timeout=0, marshal=true)
      Rack::Bug::CachePanel.record(:add, key) do
        add_without_rack_bug(key, value, timeout, marshal)
      end
    end

    def increment_with_rack_bug(key, offset=1)
      Rack::Bug::CachePanel.record(:incr, key) do
        increment_without_rack_bug(key, offset)
      end
    end

    def decrement_with_rack_bug(key, offset=1)
      Rack::Bug::CachePanel.record(:decr, key) do
        decrement_without_rack_bug(key, offset)
      end
    end

    def replace_with_rack_bug(key, value, timeout=0, marshal=true)
      Rack::Bug::CachePanel.record(:replace, key) do
        replace_without_rack_bug(key, value, timeout, marshal)
      end
    end

    def append_with_rack_bug(key, value)
      Rack::Bug::CachePanel.record(:append, key) do
        append_without_rack_bug(key, value)
      end
    end

    def prepend_with_rack_bug(key, value)
      Rack::Bug::CachePanel.record(:prepend, key) do
        prepend_without_rack_bug(key, value)
      end
    end
    
    def delete_with_rack_bug(key)
      Rack::Bug::CachePanel.record(:delete, key) do
        delete_without_rack_bug(key)
      end
    end
    
    def get_with_rack_bug(keys, marshal=true)
      if keys.is_a? Array
        Rack::Bug::CachePanel.record(:get_multi, *keys) do
          get_without_rack_bug(keys, marshal)
        end
      else
        Rack::Bug::CachePanel.record(:get, keys) do
          get_without_rack_bug(keys, marshal)
        end
      end
    end

    alias_method_chain :decrement,  :rack_bug
    alias_method_chain :get,        :rack_bug
    alias_method_chain :increment,  :rack_bug
    alias_method_chain :set,        :rack_bug
    alias_method_chain :add,        :rack_bug
    alias_method_chain :replace,    :rack_bug
    alias_method_chain :delete,     :rack_bug
    alias_method_chain :prepend,    :rack_bug
    alias_method_chain :append,     :rack_bug
  end
end

if defined?(MemCache)
  MemCache.class_eval do

    def decr_with_rack_bug(key, amount = 1)
      Rack::Bug::CachePanel.record(:decr, key) do
        decr_without_rack_bug(key, amount)
      end
    end

    def get_with_rack_bug(key, raw = false)
      Rack::Bug::CachePanel.record(:get, key) do
        get_without_rack_bug(key, raw)
      end
    end

    def get_multi_with_rack_bug(*keys)
      Rack::Bug::CachePanel.record(:get_multi, *keys) do
        get_multi_without_rack_bug(*keys)
      end
    end

    def incr_with_rack_bug(key, amount = 1)
      Rack::Bug::CachePanel.record(:incr, key) do
        incr_without_rack_bug(key, amount)
      end
    end

    def set_with_rack_bug(key, value, expiry = 0, raw = false)
      Rack::Bug::CachePanel.record(:set, key) do
        set_without_rack_bug(key, value, expiry, raw)
      end
    end

    def add_with_rack_bug(key, value, expiry = 0, raw = false)
      Rack::Bug::CachePanel.record(:add, key) do
        add_without_rack_bug(key, value, expiry, raw)
      end
    end

    def delete_with_rack_bug(key, expiry = 0)
      Rack::Bug::CachePanel.record(:delete, key) do
        delete_without_rack_bug(key, expiry)
      end
    end
    
    alias_method_chain :decr,       :rack_bug
    alias_method_chain :get,        :rack_bug
    alias_method_chain :get_multi,  :rack_bug
    alias_method_chain :incr,       :rack_bug
    alias_method_chain :set,        :rack_bug
    alias_method_chain :add,        :rack_bug
    alias_method_chain :delete,     :rack_bug
  end
end