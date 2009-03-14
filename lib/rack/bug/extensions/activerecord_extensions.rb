if defined?(ActiveRecord)
  ActiveRecord::Base.class_eval do

    if instance_methods.include?("after_initialize")
      def after_initialize_with_rack_bug
        Rack::Bug::ActiveRecordPanel.record(self.class.base_class.name)
        after_initialize_without_rack_bug
      end
    
      alias_method_chain :after_initialize, :rack_bug
    else
      def after_initialize
        Rack::Bug::ActiveRecordPanel.record(self.class.base_class.name)
      end
    end
    
  end
end