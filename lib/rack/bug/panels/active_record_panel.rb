require "rack/bug/panel"
require "rack/bug/extensions/activerecord_extensions"

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
        records = self.class.records.to_a.sort_by { |key, value| value }.reverse
        render_template "panels/active_record", :records => records
      end
      
    end
    
  end
end