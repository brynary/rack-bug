require "erb"
require 'insight/database'
require 'insight/instrumentation'
require 'insight/render'

module Insight

  # Panels are also Rack middleware
  class Panel
    include Render
    include ERB::Util
    include Database::RequestDataClient
    include Logging
    include Instrumentation::Client

    attr_reader :request

    class << self
      def file_index
        return @file_index ||= Hash.new do |h,k|
          h[k] = []
        end
      end

      def panel_exclusion
        return @panel_exclusion ||= []
      end

      def from_file(rel_path)
        old_rel, Thread::current['panel_file'] = Thread::current['panel_file'], rel_path
        require File::join('insight', 'panels', rel_path)
        return (file_index[rel_path] - panel_exclusion)
      ensure
        Thread::current['panel_file'] = old_rel
      end

      def current_panel_file
        return Thread::current['panel_file'] ||
          begin
            file_name = nil
            caller.each do |line|
              md = %r{^[^:]*insight/panels/([^:]*)\.rb:}.match line
              unless md.nil?
                file_name = md[1]
              end
            end
            file_name
          end
      end

      def inherited(sub)
        if filename = current_panel_file
          Panel::file_index[current_panel_file] << sub
        else
          warn "Insight::Panel inherited by #{sub.name} outside of an insight/panels/* file.  Discarded"
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
      logger.debug{ "Before call: #{self.name}" }
      before(env)
      status, headers, body = @app.call(env)
      @request = Rack::Request.new(env)
      logger.debug{ "After call: #{self.name}" }
      after(env, status, headers, body)
      env["insight.panels"] << self
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
