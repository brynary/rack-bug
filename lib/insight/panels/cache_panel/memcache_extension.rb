Memcached.class_eval do

  def set_with_insight(key, value, timeout=0, marshal=true)
    Insight::CachePanel.record(:set, key) do
      set_without_insight(key, value, timeout, marshal)
    end
  end

  def add_with_insight(key, value, timeout=0, marshal=true)
    Insight::CachePanel.record(:add, key) do
      add_without_insight(key, value, timeout, marshal)
    end
  end

  def increment_with_insight(key, offset=1)
    Insight::CachePanel.record(:incr, key) do
      increment_without_insight(key, offset)
    end
  end

  def decrement_with_insight(key, offset=1)
    Insight::CachePanel.record(:decr, key) do
      decrement_without_insight(key, offset)
    end
  end

  def replace_with_insight(key, value, timeout=0, marshal=true)
    Insight::CachePanel.record(:replace, key) do
      replace_without_insight(key, value, timeout, marshal)
    end
  end

  def append_with_insight(key, value)
    Insight::CachePanel.record(:append, key) do
      append_without_insight(key, value)
    end
  end

  def prepend_with_insight(key, value)
    Insight::CachePanel.record(:prepend, key) do
      prepend_without_insight(key, value)
    end
  end

  def delete_with_insight(key)
    Insight::CachePanel.record(:delete, key) do
      delete_without_insight(key)
    end
  end

  def get_with_insight(keys, marshal=true)
    if keys.is_a? Array
      Insight::CachePanel.record(:get_multi, *keys) do
        get_without_insight(keys, marshal)
      end
    else
      Insight::CachePanel.record(:get, keys) do
        get_without_insight(keys, marshal)
      end
    end
  end

  alias_method_chain :decrement,  :insight
  alias_method_chain :get,        :insight
  alias_method_chain :increment,  :insight
  alias_method_chain :set,        :insight
  alias_method_chain :add,        :insight
  alias_method_chain :replace,    :insight
  alias_method_chain :delete,     :insight
  alias_method_chain :prepend,    :insight
  alias_method_chain :append,     :insight
end

if defined?(MemCache)
  MemCache.class_eval do

    def decr_with_insight(key, amount = 1)
      Insight::CachePanel.record(:decr, key) do
        decr_without_insight(key, amount)
      end
    end

    def get_with_insight(key, raw = false)
      Insight::CachePanel.record(:get, key) do
        get_without_insight(key, raw)
      end
    end

    def get_multi_with_insight(*keys)
      Insight::CachePanel.record(:get_multi, *keys) do
        get_multi_without_insight(*keys)
      end
    end

    def incr_with_insight(key, amount = 1)
      Insight::CachePanel.record(:incr, key) do
        incr_without_insight(key, amount)
      end
    end

    def set_with_insight(key, value, expiry = 0, raw = false)
      Insight::CachePanel.record(:set, key) do
        set_without_insight(key, value, expiry, raw)
      end
    end

    def add_with_insight(key, value, expiry = 0, raw = false)
      Insight::CachePanel.record(:add, key) do
        add_without_insight(key, value, expiry, raw)
      end
    end

    def delete_with_insight(key, expiry = 0)
    end
  end

  alias_method_chain :decr,       :insight
  alias_method_chain :get,        :insight
  alias_method_chain :get_multi,  :insight
  alias_method_chain :incr,       :insight
  alias_method_chain :set,        :insight
  alias_method_chain :add,        :insight
  alias_method_chain :delete,     :insight
end
end
