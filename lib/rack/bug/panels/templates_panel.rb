require "rack/bug/extensions/actionview_extension"

module Rack
  module Bug
    
    class TemplatesPanel < Panel
      class Rendering
        attr_accessor :name
        attr_accessor :start_time
        attr_accessor :end_time
        attr_accessor :parent
        attr_reader :children
        
        
        def initialize(name)
          @name = name
          @children = []
        end
        
        def add(rendering)
          @children << rendering
          rendering.parent = self
        end
        
        def time
          @end_time - @start_time
        end
        
        def exclusive_time
          time - child_time
        end
        
        def child_time
          children.inject(0.0) { |memo, c| memo + c.time }
        end
        
        def time_summary
          if children.any?
            "%.2fms, %.2f exclusive" % [time * 1_000, exclusive_time * 1_000]
          else
            "%.2fms" % (time * 1_000)
          end
        end
        def html
          <<-HTML
            <li>
              <p>#{name} (#{time_summary})</p>
              
              #{children_html}
            </li>
          HTML
        end
        
        def children_html
          return "" unless children.any?
          
          <<-HTML
            <ul>#{joined_children_html}</ul>
          HTML
        end
        
        def joined_children_html
          children.map { |c| c.html }.join
        end
      end
      
      class Trace
        
        def start(template_name)
          rendering = Rendering.new(template_name)
          rendering.start_time = Time.now
          @current.add(rendering)
          @current = rendering
        end
        
        def finished(template_name)
          @current.end_time = Time.now
          @current = @current.parent
        end
        
        def initialize
          @current = root
        end
        
        def total_time
          root.child_time
        end
        
        def root
          @root ||= Rendering.new("root")
        end
      end
      
      def self.record(template, &block)
        template_trace.start(template)
        result = block.call
        template_trace.finished(template)
        return result
      end
      
      def self.reset
        Thread.current["rack.bug.template_trace"] = Trace.new
      end
      
      def self.template_trace
        Thread.current["rack.bug.template_trace"] ||= Trace.new
      end
      
      def name
        "templates"
      end
      
      def heading
        "Templates: %.2fms" % (self.class.template_trace.total_time * 1_000)
      end

      def content
        @template_trace = self.class.template_trace
        @template = ERB.new ::File.read(::File.dirname(__FILE__) + "/../views/panels/templates.html.erb")
        result = @template.result(binding)
        self.class.reset
        return result
      end
      
    end
    
  end
end