begin

  require 'dalli'

  Dalli::Client.class_eval do
    def perform_with_rack_bug(op, *args)
      Rack::Bug::CachePanel.record(op, args.first) do
        perform_without_rack_bug(op, *args)
      end
    end
    
    alias_method_chain :perform, :rack_bug
  end
    
rescue NameError, LoadError
end