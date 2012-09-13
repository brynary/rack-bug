# See the WARNING constant defined below for explanation
module Rack::Insight
  module MagicInsight

    # A modicum of sanity
    SAFETY_REGEX_FILTER = (/(^_)|[=\?!~<>]|save|record|persist|delete|destroy|add|remove|child|parent/).freeze

    WARNING = [
      "  # PROCEED CAREFULLY!",
      "  #",
      "  # Regarding classes which include this module:",
      "  #",
      "  # 1. Classes should be built specifically to be rendered by rack-insight,",
      "  #    and not have destructive methods.",
      "  # 2. ALL instance methods on the class (generally not from ancestors) will be called,",
      "  #    so if any are destructive you will cry.",
      "  # 3. Define ALL: Any instance methods that get past the safety regex filter.",
      "  # 4. Define safety regex filter: Rack::Insight::MagicInsight::SAFETY_REGEX_FILTER is",
      "  #",
      "  #    #{SAFETY_REGEX_FILTER.inspect}",
      "  #",
      "  # 5. To reiterate: all methods that do not match the above will be called.",
      "  #",
      "  # Classes that desire to be renderable by the magic_panel templates must:",
      "  #",
      "  #    include Rack::Insight::MagicInsight.",
      "  #",
      "  # 6. This gives explicit approval for rack-insight to call all the instance methods on your class,",
      "  #    including the kill_server method (if you have one)."
    ].freeze

    # Regex explanation:
    #   Rack::Insight - We want to keep methods that come from Rack::Insight included modules
    #   #<Class: - An ancestor matching this is probably from a class definition like this:
    #               class FooStats < Struct.new :foo, :bar
    #              We need to keep :foo and :bar from the anonymous Struct ancestor
    ANCESTORS_FILTER = /^Rack::Insight|#<Class:/.freeze

    IDIOMS = %w( backtrace time duration timing )

    def self.included(base)
      # Make sure people want to eat their lunch before we serve it to them.
      # Allows Rack::Insight namespaced classes to use MagicInsight without warnings.
      if Rack::Insight::Config.config[:silence_magic_insight_warnings] || base.to_s =~ /^Rack::Insight/
        # crickets...
      else
        warn "Rack::Insight::MagicInsight has been included in #{base}.\n#{WARNING.join("\n")}"
        raise 'Checking for dupes impossible.' if base.instance_methods.include?(:dirty_ancestors)
      end
    end

    def _dirty_ancestors
      self.class.ancestors[1..-1]
    end

    def _filtered_ancestors
      _dirty_ancestors.select {|c| !(c.to_s =~ ANCESTORS_FILTER)}
    end

    def _dirty_methods
      self.class.instance_methods - (_filtered_ancestors.map &:instance_methods).flatten
    end

    def _filtered_methods
      _dirty_methods.select {|x| !(x =~ Rack::Insight::MagicInsight::SAFETY_REGEX_FILTER)}.sort
    end

    def _sorted_methods
      _filtered_methods.sort {|a,b| a.to_s.length <=> b.to_s.length }
    end

    # If there are two methods matching an idiom, then we only want to render one of the two.
    # If there are more than two, then make no assumptions
    def _idiomatic_methods
      IDIOMS.select {|idiom| _sorted_methods.select { |meth| meth.to_s =~ /#{idiom}/ }.length == 2 }
    end

    def _has_idioms?
      !_idiomatic_methods.empty?
    end

    def _idiomatic_method(method)
      if self._has_idioms? && method = self._idiomatic_methods.select {|idiom| method.to_s =~ /#{idiom}/}.first
        method
      else
        false
      end
    end

    def _my_children
      "#{!children.empty? ? " (#{children.length} children)" : ''}" if self.respond_to?(:children)
    end

    # called by the templates
    def _magic_insight_methods
      # We want to keep the longer of the methods by num chars in the method name, because these are the ones meant for
      # humans to see (e.g. human_time, filtered_backtrace, display_time)
      sorted = _sorted_methods
      idiomatic = _idiomatic_methods
      # So we delete the shorter of the two
      idiomatic.each do |idiom|
        sorted.each_with_index do |meth, index|
          # first one found will be the shortest, so delete and move to next idiom
          if meth.to_s =~ /#{idiom}/
            sorted.delete_at(index)
            break # to idiomatic loop
          end
        end
      end
      sorted
    end

  end
end
