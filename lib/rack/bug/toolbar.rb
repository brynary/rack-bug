module Rack
  module Bug
    
    class Toolbar
      
      def panel_classes
        [TimerPanel, EnvPanel]
      end
      
      def builder
        @builder = Rack::Builder.new
        
        panel_classes.each do |panel_class|
          @builder.use panel_class
        end
        
        @builder.run @app
        return @builder
      end
      
    end
    
  end
end