if defined?(ActiveRecord)
  ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
    def log_with_rack_bug(sql, name, &block)
      start_time = Time.now
      result = log_without_rack_bug(sql, name, &block)
      Rack::Bug::SQLPanel.record(sql, Time.now - start_time)
      return result
    end
    
    alias_method_chain :log, :rack_bug
  end
end