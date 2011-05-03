if defined?(ActiveRecord)
  ActiveRecord::Base.after_initialize(:record_class_name)

  def record_class_Name
    Rack::Bug::ActiveRecordPanel.record(self.class.base_class.name)
  end
end
