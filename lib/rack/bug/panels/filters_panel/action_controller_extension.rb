if defined?(ActionController) && defined?(ActionController::Filters::Filter)
  
  ActionController::Filters::Filter.class_eval do
    
    def call_with_rack_bug(*args, &block)
      Rack::Bug::FiltersPanel.record(self) do
        call_without_rack_bug(*args, &block)
      end
    end
    
    alias_method_chain :call, :rack_bug
  end
end
