module Rack::Insight
  module Instrumentation
    class Probe
      module Interpose
      end

      @@class_list = nil

      module ProbeRunner
        include Backstage
        include Logging

        def probe_run(object, context = "::", kind=:instance, args=[], called_at=caller[1], method_name = nil)
          if Thread.current['instrumented_backstage']
            #warn "probe_run while backstage: #{context}, #{kind},
            ##{method_name}" unless method_name.to_sym == :add
            return yield
          end
          instrument = Thread.current['rack-insight.instrument']
          result = nil
          if instrument.nil?
            backstage do
              result = yield
            end
          else
            instrument.run(object, context, kind, called_at, method_name, args){ result = yield }
          end
          result
        end
        extend self
      end

      class << self
        include Logging

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
              logger.warn{ "Cannot find constant: #{k}" } if verbose(:med)
              false
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
      end

      def collectors(key)
        @collectors[key.to_sym]
      end

      def all_collectors
        @collectors.values
      end

      def clear_collectors
        @collectors.clear
      end

      def probe(collector, *methods)
        methods.each do |name|
          unless @collectors[name.to_sym].include?(collector)
            @collectors[name.to_sym] << collector
          end
          @probe_orders << name
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
          (@const != klass and local_method_defs(klass).include?(method_name))
        end
      end

      include Logging
      def log &block
        if verbose(:debug)
          logger.debug &block
        end
      end

      def fulfill_probe_orders
        log{{:probes_for => @const.name, :type => self.class}}
        @probe_orders.each do |method_name|
          log{{ :method => method_name }}
          build_tracing_wrappers(@const, method_name)
          descendants_that_define(method_name).each do |klass|
            log{{ :subclass => klass.name }}
            build_tracing_wrappers(klass, method_name)
          end
        end
        @probe_orders.clear
      end

      def get_method(klass, method_name)
        klass.instance_method(method_name)
      end

      def define_trace_method(target, method)
        target.class_exec() do
          define_method(method.name) do |*args, &block|
            ProbeRunner::probe_run(self, method.owner.name, :instance, args, caller(0)[0], method.name) do
              method.bind(self).call(*args, &block)
            end
          end
        end
      end

      def build_tracing_wrappers(target, method_name)
        return if @probed.has_key?([target,method_name])
        @probed[[target,method_name]] = true

        meth = get_method(target, method_name)

        log{ {:tracing => meth } }
        define_trace_method(target, meth)
      rescue NameError => ne
        log{ {:not_tracing => NameError } }
      end
    end

    class ClassProbe < Probe
      def local_method_defs(klass)
        klass.singleton_methods(false)
      end

      def get_method(klass, method_name)
        (class << klass; self; end).instance_method(method_name)
      end

      def define_trace_method(target, method)
        (class << target; self; end).class_exec() do
          define_method(method.name) do |*args, &block|
            ProbeRunner::probe_run(self, target.name, :class, args, caller(0)[0], method.name) do
              method.bind(self).call(*args, &block)
            end
          end
        end
      end
    end

    class InstanceProbe < Probe
    end
  end
end
