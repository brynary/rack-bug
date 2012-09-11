module Rack::Insight

  class MemoryPanel < Panel

    def before(env)
      @original_memory = `ps -o rss= -p #{$$}`.to_i
    end

    def after(env, status, headers, body)
      total_memory = `ps -o rss= -p #{$$}`.to_i
      store(env, {:total_memory => total_memory,
            :memory_increase => total_memory - @original_memory,
            :original_memory => @original_memory})
    end

    def heading_for_request(number)
      record = retrieve(number).first

      "#{record[:memory_increase]} KB &#916;, #{record[:total_memory]} KB total"
    end

    def has_content?
      false
    end

  end

end
