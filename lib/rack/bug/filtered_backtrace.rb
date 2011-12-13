module Rack
  class Bug
    module FilteredBacktrace

      def backtrace
        @backtrace
      end

      def has_backtrace?
        filtered_backtrace.any?
      end

      def filtered_backtrace
        @filtered_backtrace ||= @backtrace.map{|l| l.to_s.strip }.select do |line|
          root_for_backtrace_filtering.nil? ||
          (line.index(root_for_backtrace_filtering.to_s) == 0) && !(line.index(root_for_backtrace_filtering("vendor").to_s) == 0)
        end
      end

      def root_for_backtrace_filtering(sub_path = nil)
        if defined?(Rails) && Rails.respond_to?(:root)
          (sub_path ? Rails.root.join(sub_path) : Rails.root).to_s
        else
          root = if defined?(RAILS_ROOT)
            RAILS_ROOT
          elsif defined?(ROOT)
            ROOT
          elsif defined?(Sinatra::Application)
            Sinatra::Application.root
          else
            nil
          end
          sub_path ? ::File.join(root, sub_path) : root
        end.to_s
      end
    end
  end
end
