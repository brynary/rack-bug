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

    # has table defaults to true for panels.
    def self.has_table
      self.has_table.nil? ? true : self.class.table.nil?
    end

    class << self

      include Rack::Insight::Logging
      # This will allow the following:
      # p = Panel.new
      # p.class.is_probing = true
      include Rack::Insight::Instrumentation::EigenClient
      include Rack::Insight::Database::EigenClient

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
        num_load_paths_to_check = Rack::Insight::Config.config[:panel_load_paths].length
        Rack::Insight::Config.config[:panel_load_paths].each_with_index do |load_path, index|
          begin
            require File::join(load_path, rel_path)
            break # once found
          rescue LoadError => e
            # TODO: If probes are defined for this panel, instantiate a magic panel
            # if self.has_custom_probes?
            if !verbose(:high) && (index + 1) == num_load_paths_to_check # You have failed me for the last time!
              warn "Rack::Insight #{e.class} while attempting to load '#{rel_path}' from :panel_load_paths #{Rack::Insight::Config.config[:panel_load_paths].inspect}."
            elsif verbose(:high)
              warn "Rack::Insight #{e.class} #{e.message} while attempting to load '#{rel_path}' from :panel_load_paths #{Rack::Insight::Config.config[:panel_load_paths].inspect} (just checked: #{load_path})."
            end
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
      #     config[:panel_configs][:log] = {:probes => {'Logger' => [:instance, :add] } }
      #     # OR EQUIVALENTLY
      #     config[:panel_configs][:log] = {:probes => ['Logger', :instance, :add] }
      #   end
      panel_name = self.underscored_name.to_sym
      if self.has_custom_probes?(panel_name)
        # Both formats are valid and must be supported
        #config[:panel_configs][:log] = {:probes => {'Logger' => [:instance, :add]}}
        #config[:panel_configs][:log] = {:probes => ['Logger', :instance, :add]}
        custom_probes = Rack::Insight::Config.config[:panel_configs][panel_name][:probes]
        if custom_probes.kind_of?(Hash)
          probe(self) do
            custom_probes.each do |klass, method_probes|
              instrument klass do
                self.send("#{method_probes[0]}_probe", *(method_probes[1..-1]))
              end
            end
          end
        elsif custom_probes.kind_of?(Array) && custom_probes.length >=3
          probe(self) do
            custom_probes.each do |probe|
              klass = probe.shift
              probe_type = probe.shift
              instrument klass do
                self.send("#{probe_type}_probe", *probe)
              end
            end
          end
        else
          raise "Expected Rack::Insight::Config.config[:panel_configs][#{panel_name}][:probes] to be a kind of Hash or an Array with length >= 3, but is a #{Rack::Insight::Config.config[:panel_configs][self.as_sym][:probes].class}"
        end
      end

      # Setup a table for the panel unless
      # 1. self.has_table = false has been set for the Panel class
      # 2. class instance variable @has_table has been set to false
      # 3. table_setup has already been called by the sub class' initializer
      if !has_table?
        table_setup(self.name)
      end
    end

    def inspect
      "#{self.underscored_name} Magic:#{self.bool_prop(:is_magic?)} Table:#{self.bool_prop(:has_table?)} Probe:#{self.bool_prop(:is_probing?)} Custom:#{self.bool_prop(:has_custom_probes?)}" rescue "XXX inspect failed"
    end

    def bool_prop(prop)
      self.send(prop) ? 'Y' : 'N'
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

    def has_table?
      !!self.class.has_table
    end

    def is_magic?
      !!self.class.is_magic
    end

    def has_content?
      true
    end

    def is_probing?
      !!self.class.is_probing
    end

    def has_custom_probes?(panel_name = self.underscored_name.to_sym)
      Rack::Insight::Config.config[:panel_configs][panel_name].respond_to?(:[]) &&
        !Rack::Insight::Config.config[:panel_configs][panel_name][:probes].nil?
    end

    # The name informs the table name, and the panel_configs hash among other things.
    # Override in subclass panels if you want a custom name
    def name
      self.underscored_name
    end

    # Mostly stolen from Rails' ActiveSupport' underscore method:
    # See activesupport/lib/active_support/inflector/methods.rb, line 77
    # HTTPClientPanel => http_client
    # LogPanel => log
    # ActiveRecordPanel => active_record
    def underscored_name(word = self.class.to_s)
      @underscored_name ||= begin
        words = word.dup.split('::')
        word = words.last
        if word == 'Panel'
          word = words[-2] # Panel class is Panel... and this won't do.
        end
        # This bit from rails probably isn't needed here, and wouldn't work anyways.
        #word.gsub!(/(?:([A-Za-z\d])|^)(#{inflections.acronym_regex})(?=\b|[^a-z])/) { "#{$1}#{$1 && '_'}#{$2.downcase}" }
        word.gsub!(/Panel$/,'')
        word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        word.tr!("-", "_")
        word.downcase!
        word
      end
    end

    def camelized_name(str = self.underscored_name)
      str.split('_').map {|w| w.capitalize}.join
    end

    def heading_for_request(number)
      if !self.has_table?
        heading
      else
        num = count(number)
        if num.kind_of?(Numeric)
          if num == 0
            heading
          else
            "#{self.camelized_name} (#{num})"
          end
        else
          heading
        end
      end
    rescue StandardError => exception
      handle_error_for('heading_for_request', exception)
    end

    def content_for_request(number)
      logger.info("Rack::Insight is using default content_for_request for #{self.class}") if verbose(:med)
      if !self.has_table?
        logger.info("#{self.class} is being used without a table") if verbose(:med)
        content
      elsif self.is_probing? # Checking probed because we only get here when the subclass panel hasn't overridden this method
        invocations = retrieve(number)
        if invocations.length > 0
          logger.info("Rack::Insight is using #{self.is_magic? ? 'magic' : 'default'} content for #{self.class}, which is probed")# if verbose(:med)
          render_template 'magic_panel', :magic_insights => invocations, :name => self.camelized_name
        else
          logger.info("Rack::Insight has no data for #{self.is_magic? ? 'magic' : 'default'} content for #{self.class}, which is probed")
          render_template 'no_data', :name => self.camelized_name
        end
      else
        content
      end
    rescue StandardError => exception
      handle_error_for('content_for_request', exception)
    end

    def heading
      self.camelized_name
    rescue StandardError => exception
      handle_error_for('heading', exception)
    end

    def content
      logger.info("Rack::Insight is using default content for #{self.class}") if verbose(:med)
      render_template 'no_content', :name => self.camelized_name
    rescue StandardError => exception
      handle_error_for('content', exception)
    end

    def handle_error_for(method_name, exception)
      nom = self.name rescue "xxx"
      msg = ["#{self.class}##{method_name} failed","#{exception.class}: #{exception.message}"] + exception.backtrace
      logger.error(msg.join("\n"))
      # return HTML
      "Error in #{nom}
      <!-- Panel: #{self.inspect}\n
      #{msg.join("\n")} -->"
    end

    # Override in subclasses.
    # This is to make magic classes work.
    def after_detect(method_call, timing, args, result)
      if self.is_magic? && self.has_table? && self.is_probing?
        store(@env, Rack::Insight::DefaultInvocation.new(method_call.method.to_s, timing, args, result, method_call.backtrace[2..-1]))
      end
    end

    def before(env)
    end

    def after(env, status, headers, body)
    end

    def render(template)
    end

  end

end
