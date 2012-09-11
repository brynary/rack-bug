module Rack::Insight
  module FilteredBacktrace

    def backtrace
      @backtrace
    end

    def has_backtrace?
      filtered_backtrace.any?
    end

    def filtered_backtrace
      @filtered_backtrace ||= @backtrace.respond_to?(:grep) ? @backtrace.grep(FilteredBacktrace.backtrace_regexp) : []
    end

    def self.backtrace_regexp
      @backtrace_regexp ||=
        begin
          if !Rack::Insight::Config.filtered_backtrace || (app_root = root_for_backtrace_filtering).nil?
            /.*/
          else
            excludes = %w{vendor}
            %r{^#{app_root}(?:#{::File::Separator}(?!#{excludes.join("|")}).+)$}
          end
        end
    end

    def self.root_for_backtrace_filtering(sub_path = nil)
      if defined?(Rails) && Rails.respond_to?(:root)
        sub_path ? Rails.root.join(sub_path) : Rails.root
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
      end
    end
  end
end
