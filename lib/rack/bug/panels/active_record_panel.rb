require "rack/bug/panels/active_record_panel/activerecord_extensions"

module Rack
  module Bug
    
    class ActiveRecordPanel < Panel
      
      def self.record(class_name)
        return unless Rack::Bug.enabled?
        records[class_name] += 1
      end
      
      def self.reset
        Thread.current["rack.bug.active_records"] = Hash.new { 0 }
      end
      
      def self.records
        Thread.current["rack.bug.active_records"] ||= Hash.new { 0 }
      end
      
      def self.total
        records.inject(0) do |memo, (key, value)|
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
        result = render_template "panels/active_record", :records => records
        self.class.reset
        result
      end
      
    end
    
  end
end