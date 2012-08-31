require "erb"
require "rack/insight/logging"
require 'rack/insight/database'
require 'rack/insight/instrumentation'
require 'rack/insight/render'

module Rack::Insight

  # Panels are also Rack middleware
  class Panel
    include ERB::Util
    include Rack::Insight::Logging
    include Rack::Insight::Render
    include Rack::Insight::Database::RequestDataClient
    include Rack::Insight::Instrumentation::Client

    attr_reader :request

    class << self
      attr_accessor :template_root
      def file_index
        return @file_index ||= Hash.new do |h,k|
          h[k] = []
        end
      end

      def panel_exclusion
        return @panel_exclusion ||= []
      end

      def from_file(rel_path)
        old_rel, Thread::current['rack-panel_file'] = Thread::current['rack-panel_file'], rel_path
        Rack::Insight::Config.config[:panel_load_paths].each do |load_path|
          begin
            require File::join(load_path, rel_path)
          rescue LoadError => e
          end
        end
        return (file_index[rel_path] - panel_exclusion)
      ensure
        Thread::current['rack-panel_file'] = old_rel
      end

      def current_panel_file(sub)
        return Thread::current['rack-panel_file'] ||
          begin
            file_name = nil
            matched_line = nil
            caller.each do |line|
              # First make sure we are not matching rack-insight's own panel class, which will be in the caller stack,
              # and which may match some custom load path added (try adding 'rack' as a custom load path!)
              next if line =~ /rack-insight.*\/lib\/rack\/insight\/panel.rb:/
              Rack::Insight::Config.config[:panel_load_paths].each do |load_path|
                regex = %r{^[^:]*#{load_path}/([^:]*)\.rb:}
                md = regex.match line
                file_name = md[1] unless md.nil?
                matched_line = line unless file_name.nil?
                break unless file_name.nil?
              end
              break unless file_name.nil?
            end
            sub.template_root = File.dirname(matched_line.split(':')[0]) if matched_line.respond_to?(:split)
            file_name
          end
      end

      def inherited(sub)
        if filename = current_panel_file(sub)
          Panel::file_index[filename] << sub
        else
          warn "Rack::Insight::Panel inherited by #{sub.name} outside rack-insight's :panel_load_paths.  Discarded.  Configured panel load paths are: #{Rack::Insight::Config.config[:panel_load_paths].inspect}"
        end
      end

      def excluded(klass = nil)
        Panel::panel_exclusion << klass || self
      end

    end

    def initialize(app)
      if panel_app
        #XXX use mappings
        @app = Rack::Cascade.new([panel_app, app])
      else
        @app = app
      end
    end

    def call(env)
      @env = env
      logger.debug{ "Before call: #{self.name}" } if verbose(:debug)
      before(env)
      status, headers, body = @app.call(env)
      @request = Rack::Request.new(env)
      logger.debug{ "After call: #{self.name}" } if verbose(:debug)
      after(env, status, headers, body)
      env["rack-insight.panels"] << self
      return [status, headers, body]
    end

    def panel_app
      nil
    end

    def self.panel_mappings
      {}
    end

    def has_content?
      true
    end

    def name
      "Unnamed panel: #{self.class.name}" #for shame
    end

    def heading_for_request(number)
      heading rescue "xxx" #XXX: no panel should need this
    end

    def content_for_request(number)
      content rescue "" #XXX: no panel should need this
    end

    def before(env)
    end

    def after(env, status, headers, body)
    end

    def render(template)
    end

  end

end
