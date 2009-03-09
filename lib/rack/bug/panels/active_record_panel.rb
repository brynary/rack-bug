require "rack/bug/panel"

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

module Rack
  module Bug
    
    class ActiveRecordPanel < Panel
      
      def self.record(class_name)
        Thread.current["rack.bug.active_records"] ||= {}
        Thread.current["rack.bug.active_records"][class_name] ||= 0
        Thread.current["rack.bug.active_records"][class_name] += 1
      end
      
      def self.reset
        Thread.current["rack.bug.active_records"] = {}
      end
      
      def self.records
        Thread.current["rack.bug.active_records"] || {}
      end
      
      def self.total
        Thread.current["rack.bug.active_records"] ||= {}
        Thread.current["rack.bug.active_records"].inject(0) do |memo, (key, value)|
          memo + value
        end
      end
      
      def name
        "active_record"
      end
      
      def heading
        "#{self.class.total} AR Objects"
      end
      
      def content
        @records = self.class.records
        @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/../views/panels/active_record.html.erb")
        @template.result(binding)
      end
      
    end
    
  end
end