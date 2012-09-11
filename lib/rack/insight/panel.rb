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
    attr_accessor :probed

    class << self

      include Rack::Insight::Logging

      attr_accessor :template_root, :tableless
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

      def set_sub_class_template_root(sub_class, path)
        sub_class.template_root = path
      end

      def current_panel_file(sub)
        file_name = nil
        matched_line = nil
        caller.each do |line|
          # First make sure we are not matching rack-insight's own panel class, which will be in the caller stack,
          # and which may match some custom load path added (try adding 'rack' as a custom load path!)
          # .*panel because the panels that ship with rack-insight also do not need custom template roots.
          next if line =~ /rack-insight.*\/lib\/rack\/insight\/.*panel.rb:/
          Rack::Insight::Config.config[:panel_load_paths].each do |load_path|
            regex = %r{^[^:]*#{load_path}/([^:]*)\.rb:}
            md = regex.match line
            file_name = md[1] unless md.nil?
            matched_line = line unless file_name.nil?
            break unless file_name.nil?
          end
          break unless file_name.nil?
        end
        set_sub_class_template_root(sub, File.dirname(matched_line.split(':')[0])) if matched_line.respond_to?(:split)
        return Thread::current['rack-panel_file'] || file_name
      end

      def inherited(sub)
        if filename = current_panel_file(sub)
          logger.debug("panel inherited by #{sub.inspect} with template_root: #{sub.template_root}") if verbose(:high)
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

      # User has explicitly declared what classes/methods to probe:
      #   Rack::Insight::Config.configure do |config|
      #     config[:panel_configs][:log_panel] = {:watch => {'Logger' => :add}}
      #   end
      if !Rack::Insight::Config.config[:panel_configs][self.as_sym].respond_to?(:[])
        if Rack::Insight::Config.config[:panel_configs][self.as_sym][:probes].kind_of?(Hash)
          probe(self) do
            Rack::Insight::Config.config[:panel_configs][self.as_sym][:probes].each do |klass, *method_probes|
              probe_type = method_probes.shift
              puts "probe_type: #{probe_type.inspect}"
              instrument klass do
                self.send("#{probe_type}_probe", method_probes)
              end
            end
          end
        else
          raise "Expected Rack::Insight::Config.config[:panel_configs][#{self.as_sym.inspect}][:probes] to be a kind of Hash, but is a #{Rack::Insight::Config.config[:panel_configs][self.as_sym][:probes].class}"
        end
      end

      # Setup a table for the panel unless
      # 1. no_table has been called
      # 2. @table has been set to false
      # 3. table_setup has already been called
      table_setup("#{self.name}_entries") unless tableless?
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

    def tableless?
      !!self.class.tableless
    end

    def has_content?
      true
    end

    def already_probed?
      !!@probed
    end

    # The name informs the table name, and the panel_configs hash among other things.
    # Override in subclass panels if you want a custom name
    def name
      self.underscored_name
    end

    def as_sym
      @as_sym ||= self.name.to_sym
    end

    # Mostly stolen from Rails' ActiveSupport' underscore method:
    def underscored_name
      @underscored_name ||= begin
        self.class.to_s.
          gsub(/Panel/,'').
          gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end
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
