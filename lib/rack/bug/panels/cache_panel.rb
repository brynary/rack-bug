require "rack/bug/extensions/memcache_extension"

module Rack
  module Bug
    
    class CachePanel < Panel
      
      def self.record(action, *keys, &block)
        Thread.current["rack.bug.cache_calls"] ||= 0
        Thread.current["rack.bug.cache_time"] ||= 0.0
        Thread.current["rack.bug.cache_calls"] += 1
        
        start_time = Time.now
        result = block.call
        total_time = Time.now - start_time
        Thread.current["rack.bug.cache_time"] += (total_time * 1_000)
        return result
      end
      
      def self.reset
        Thread.current["rack.bug.cache_calls"] = 0
        Thread.current["rack.bug.cache_time"] = 0.0
      end
      
      def self.cache_calls
        Thread.current["rack.bug.cache_calls"] || 0
      end
      
      def self.cache_time
        Thread.current["rack.bug.cache_time"] || 0.0
      end
      
      def name
        "cache"
      end
      
      def heading
        "#{self.class.cache_calls} Cache Actions: #{self.class.cache_time}ms"
      end

      def content
        @cache_calls = self.class.cache_calls
        @cache_time = self.class.cache_time
        @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/../views/panels/cache.html.erb")
        result = @template.result(binding)
        self.class.reset
        return result
      end
      
    end
    
  end
end