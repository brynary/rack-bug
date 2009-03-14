module Rack
  module Bug
    
    class RailsInfoPanel < Panel
      
      def name
        "rails_info"
      end
      
      def heading
        return unless defined?(Rails)
        "Rails #{Rails.version}"
      end

      def content
        return unless defined?(Rails)
        @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/../views/panels/rails_info.html.erb")
        @template.result(binding)
      end
      
    end
    
  end
end
