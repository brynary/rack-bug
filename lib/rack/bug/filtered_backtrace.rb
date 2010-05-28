module Rack
  module Bug
    module FilteredBacktrace

      def backtrace
        @backtrace
      end
      
      def has_backtrace?
        filtered_backtrace.any?
      end

      def filtered_backtrace
        @filtered_backtrace ||= @backtrace.map{|l| l.to_s.strip }.select do |line|
          !defined?(Rails) ||
          !Rails.respond_to?(:root) ||
          (line.starts_with?(Rails.root) && !line.starts_with?(Rails.root.join("vendor")))
        end
      end
    end
  end
end
