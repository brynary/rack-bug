if defined?(ActiveRecord)
  ActiveRecord::Base.after_initialize(:record_class_name)

  module RackBugExtension
    def record_class_name
      Rack::Bug::ActiveRecordPanel.record(self.class.base_class.name)
    end
  end
  class ActiveRecord::Base
    include RackBugExtension
  end

end
