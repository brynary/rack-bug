class Rack::Bug
  module Instrumentation
    class PackageDefinition
      class << self
        def start
          @started = begin
                       probes.each do |probe|
                         probe.fulfill_probe_orders
                       end
                       true
                     end
        end

        def probes
          InstanceProbe.all_probes + ClassProbe.all_probes
        end

        def all_collectors
          @all_collectors ||= []
        end

        def add_collector(collector)
          unless all_collectors.include?(collector)
            all_collectors << collector
          end
        end

        def probe(collector, &block)
          add_collector(collector)
          definer = self.new(collector)
          definer.instance_eval &block
        end
      end

      def get_class_probe(name)
        ClassProbe.probe_for(name)
      end

      def get_instance_probe(name)
        InstanceProbe.probe_for(name)
      end

      def initialize(collector)
        @collector = collector
      end

      attr_reader :collector

      def instrument(name, &block)
        definer = ProbeDefinition.new(self, name)
        definer.instance_eval(&block) unless block.nil?
        return definer
      end
    end

    class ProbeDefinition
      def initialize(package, target_name)
        @package = package
        @target_name = target_name
      end

      def instance_probe(*method_names)
        if probes = @package.get_instance_probe(@target_name)
          probes.probe(@package.collector, *method_names)
        end
      end

      def class_probe(*method_names)
        if probes = @package.get_class_probe(@target_name)
          probes.probe(@package.collector, *method_names)
        end
      end
    end

    module Backstage
      def backstage
        Thread.current["instrumented_backstage"] = true
        yield
      ensure
        Thread.current["instrumented_backstage"] = false
      end
    end


    class Probe
      @@class_list = nil

      module ProbeRunner
        include Backstage

        def probe_run(object, context = "::", kind=:instance, called_at=caller[1], args=[])
          return yield if Thread.current['instrumented_backstage']
          instrument = Thread.current['rack-bug.instrument']
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

    module Client
      def probe(collector, &block)
        Instrumentation::PackageDefinition::probe(collector, &block)
      end

      def request_start(env, start)
      end

      def before_detect(method_call, arguments)
      end

      def after_detect(method_call, timing, arguments, result)
      end

      def request_finish(env, status, headers, body, timing)
      end
    end

    class Instrument

      MethodCall = Struct.new(:call_number, :backtrace, :file, :line, :object, :context, :kind, :method, :thread)
      class Timing
        def initialize(request_start, start, finish)
          @request_start, @start, @finish = request_start, start, finish
        end

        attr_reader :request_start, :start, :finish

        def duration
          @duration ||= ((@finish - @start) * 1000).to_i
        end

        def delta_t
          @delta_t ||= ((@start - @request_start) * 1000).to_i
        end
      end

      @@call_seq = 0

      def self.seq_number
        Thread.exclusive do
          return @@call_seq += 1
        end
      end

      def initialize()
        @start = Time.now
        @collectors = nil
      end

      include Backstage

      def run(object, context="::", kind=:instance, called_at = caller[0], args=[], &blk)
        file, line, method = called_at.split(':')
        method = method.gsub(/^in|[^\w]+/, '') if method
        call_number = backstage{ self.class.seq_number }
        method_call = backstage{ MethodCall.new(call_number, caller(1), file, line, object, context, kind, method, Thread::current) }
        #$stderr.puts [method_call.context, method_call.method].inspect
        start_time = Time.now
        backstage do
          start_event(method_call, args)
        end
        result = blk.call      # execute the provided code block
        backstage do
          finish_event(method_call, args, start_time, result)
        end
      end

      def collectors_for(method_call)
        probe_chain = if method_call.kind == :instance
                        InstanceProbe.get_probe_chain(method_call.context)
                      else
                        ClassProbe.get_probe_chain(method_call.context)
                      end
        collectors = probe_chain.inject([]) do |list, probe|
          probe.collectors(method_call.method)
        end
        collectors
      end

      def start_event(method_call, arguments)
        collectors_for(method_call).each do |collector|
          collector.before_detect(method_call, arguments)
        end
      end

      def finish_event(method_call, arguments, start_time, result)
        timing = Timing.new(@start, start_time, Time.now)
        collectors_for(method_call).each do |collector|
          collector.after_detect(method_call, timing, arguments, result)
        end
      end

      def all_collectors
        PackageDefinition.all_collectors
      end

      def start(env)
        all_collectors.each do |collector|
          collector.request_start(env, @start)
        end
      end

      def finish(env, status, headers, body)
        @timing = Timing.new(@start, @start, Time.now)
        all_collectors.each do |collector|
          collector.request_finish(env, status, headers, body, @timing)
        end
      end

      def duration
        @timing.duration
      end
    end
  end
end
