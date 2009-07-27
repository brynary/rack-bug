if defined?(ActiveRecord) &&  defined?(ActiveRecord::ConnectionAdapters)
  ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
    def log_with_rack_bug(sql, name, &block)
      Rack::Bug::SQLPanel.record(sql, Kernel.caller) do
        log_without_rack_bug(sql, name, &block)
      end
    end
    
    alias_method_chain :log, :rack_bug
  end
end