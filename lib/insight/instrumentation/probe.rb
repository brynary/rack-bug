module Insight
  module Instrumentation
    class Probe
      @@class_list = nil

      module ProbeRunner
        include Backstage

        def probe_run(object, context = "::", kind=:instance, called_at=caller[1], args=[])
          return yield if Thread.current['instrumented_backstage']
          instrument = Thread.current['insight.instrument']
          result = nil
          if instrument.nil?
            backstage do
              # Rails.logger.debug{"No instrument in thread - #{context} /
              # #{called_at}"}
              result = yield
            end
          else
            instrument.run(object, context, kind, called_at, args){ result = yield }
          end
          result
        end
        extend self
      end

      class << self
        def class_list
          @@class_list ||= begin
                             classes = []
                             ObjectSpace.each_object(Class) do |klass|
                               classes << klass
                             end
                             classes
                           end
        end

        def get_probe_chain(name)
          const = const_from_name(name)
          chain = []
          const.ancestors.each do |mod|
            if probes.has_key?(mod.name)
              chain << probes[mod.name]
            end
          end
          chain
        end

        def const_from_name(name)
          parts = name.split("::")
          const = parts.inject(Kernel) do |namespace, part|
            namespace.const_get(part)
          end
        end

        def probes
          @probes ||= Hash.new do |h,k|
            begin
              h[k] = self.new(const_from_name(k))
            rescue NameError
              warn "Cannot find constant: #{k}"
            end
          end
        end

        def all_probes
          probes.values
        end

        def probe_for(const)
          probes[const]
        end
      end

      def initialize(const)
        @const = const
        @probed = {}
        @collectors = Hash.new{|h,k| h[k] = []}
        @probe_orders = []
        @unsafe_names = (target(@const).public_instance_methods(true) +
                         target(@const).protected_instance_methods(true) +
                         target(@const).private_instance_methods(true)).sort.uniq
      end

      def collectors(key)
        @collectors[key.to_sym]
      end

      def all_collectors
        @collectors.values
      end

      def target(const)
        const
      end

      def context_string
        '#{self.class.name}'
      end

      def kind
        :instance
      end

      def probe(collector, *methods)
        methods.each do |name|
          @collectors[name.to_sym] << collector
          @collectors[name.to_sym].uniq!
        end

        safe_method_names(methods).each do |method_name, old_method|
          @probe_orders << [method_name, old_method]
        end
      end

      def safe_method_names(method_names)
        method_names.map do |name|
          name = name.to_s
          prefix = "0"
          hidden_name = ["_", prefix, name].join("_")
          while @unsafe_names.include?(hidden_name)
            prefix = prefix.next
            hidden_name = ["_", prefix, name].join("_")
          end

          @unsafe_names << hidden_name
          [name, hidden_name]
        end
      end

      def descendants
        @descendants ||= self.class.class_list.find_all do |klass|
          klass.ancestors.include?(@const)
        end
      end

      def local_method_defs(klass)
        klass.instance_methods(false)
      end

      def descendants_that_define(method_name)
        log{{ :descendants => descendants }}
        descendants.find_all do |klass|
          (@const == klass or local_method_defs(klass).include?(method_name))
        end
      end

      def log &block
        #$stderr.puts block.call.inspect
      end

      def fulfill_probe_orders
        log{{:probes_for => @const.name, :kind => kind }}
        @probe_orders.each do |method_name, old_method|
          log{{ :method => method_name }}
          descendants_that_define(method_name).each do |klass|
            log{{ :subclass => klass.name }}
            build_tracing_wrappers(target(klass), method_name, old_method)
          end
        end
      end

      def absolute_method_name(method_name)
        "#@const##{method_name}"
      end

      if(defined? awesomeness)
        def trace_class_methods(*methods_names)
          @class_interpose ||=
            begin
              mod = Module.new do
                include TraceRunner
              end
              Interpose::const_set((@const.name.gsub(/::/, "") + "Class").to_sym, mod)
              mod
            end
          build_tracing_wrappers((
            class << @const; self; end), @class_interpose, '#{self.name}::', *methods_names)
        end

        def trace_methods(*methods)
          @instance_interpose ||=
            begin
              mod = Module.new do
                include TraceRunner
              end
              Interpose::const_set((@const.name.gsub(/::/, "") + "Instance").to_sym, mod)
              mod
            end
          build_tracing_wrappers(@const, @instance_interpose, '#{self.class.name}#', *methods)
        end

        def build_tracing_wrappers(target, interpose_module, context, *methods)
          unless target.include?(interpose_module)
            target.class_eval do
              include interpose_module
            end
          end

          methods.each do |method_name|
            next if @traced.has_key?(method_name)
            @traced[method_name] = true

            if target.instance_methods(false).include?(method_name.to_s)
              meth = target.instance_method(method_name)

              interpose_module.instance_eval do
                define_method(method_name, meth)
              end
            end

            require 'ruby-debug'

            target.class_eval do
              define_method(method_name) do |*args|
                trace_run(context, caller(0)[0], args) do
                  super
                end
              end
            end
          end

          return nil
        end

      end

      def build_tracing_wrappers(target, method_name, old_method)
        return if @probed.has_key?(method_name)
        @probed[method_name] = true

        #TODO: nicer chaining
        target.class_eval <<-EOC, __FILE__, __LINE__
          alias #{old_method} #{method_name}
          def #{method_name}(*args, &block)
            ProbeRunner::probe_run(self, "#{context_string}", :#{kind}, caller(0)[0], args) do
          #{old_method}(*args, &block)
            end
          end
          EOC
      rescue NameError
        warn "Probed target method #{absolute_method_name(method_name)} isn't definied"
      end
    end

    class ClassProbe < Probe
      def target(const)
        class << const
          self;
        end
      end

      def local_method_defs(klass)
        klass.singleton_methods(false)
      end

      def context_string
        '#{self.name}'
      end

      def absolute_method_name(method_name)
        "#@const::#{method_name}"
      end

      def kind
        :class
      end
    end

    class InstanceProbe < Probe
    end
  end
end
