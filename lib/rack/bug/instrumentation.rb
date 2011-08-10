class Rack::Bug
  module Instrumentation
    class PackageDefinition
      @probes = Hash.new do |h,k|
        h[k] = Probe.new(k)
      end

      class << self
        def get_probe(const)
          return @probes[const]
        end

        def probes
          @probes.values
        end

        def probe(collector, &block)
          definer = self.new(collector)
          definer.instance_eval &block
        end
      end

      def initialize(collector)
        @collector = collector
      end

      def instrument(name, &block)
        probe = begin
                  self.class.get_probe(name)
                rescue NameError => ex
                  warn "Couldn't find #{name}"
                  return nil
                end
        definer = ProbeDefinition.new(@collector, probe)

        definer.instance_eval(&block) unless block.nil?
        return probe
      end
    end

    class ProbeDefinition
      def initialize(collector, probe)
        @collector = collector
        @probe = probe
      end

      def instance_probe(*method_names)
        @probe.instance_probe(@collector, *method_names)
      end

      def class_probe(*method_names)
        @probe.class_probe(@collector, *method_names)
      end
    end


    module Client
      def probe(collector, &block)
        Instrumentation::PackageDefinition::probe(collector, &block)
      end
    end

    class Probe
      module ProbeRunner
        def probe_run(context = "::", kind=:instance, called_at=caller[1], args=[])
          instrument = Thread.current['rack-bug.instrument']
          result = nil
          if instrument.nil?
            Rails.logger.debug{"No instrument in thread - #{context} / #{called_at}"}
            result = yield
          else
            instrument.run(context, kind, called_at, args){ result = yield }
          end
          result
        end
        extend self
      end

      def initialize(name)

        parts = name.split("::")
        const = parts.inject(Kernel) do |namespace, part|
          namespace.const_get(part)
        end
        @const = const
        @probed = {}
        @collectors = Hash.new{|h,k| h[k] = []}
        @unsafe_names = (@const.public_instance_methods(true) +
                         @const.protected_instance_methods(true) +
                         @const.private_instance_methods(true)).sort.uniq
      end

      def collectors(key)
        key = key.map{|part| part.to_sym}
        @collectors[key]
      end

      def all_collectors
        @collectors.values
      end

      def class_probe(collector, *methods_names)
        build_tracing_wrappers(collector, (
          class << @const;
            self;
          end), '#{self.name}', :class, *methods_names)
      end

      def instance_probe(collector, *methods)
        build_tracing_wrappers(collector, @const, '#{self.class.name}', :instance, *methods)
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

      def build_tracing_wrappers(collector, target, context, kind, *methods)
        methods.each do |name|
          @collectors[[name.to_sym, kind]] << collector
          @collectors[[name.to_sym, kind]].uniq!
        end

        safe_method_names(methods).each do |method_name, old_method|
          next if @probed.has_key?(method_name)
          @probed[method_name] = true

          #TODO: nicer chaining
          target.class_eval <<-EOC, __FILE__, __LINE__
          alias #{old_method} #{method_name}
          def #{method_name}(*args, &block)
            ProbeRunner::probe_run("#{context}", :#{kind}, caller(0)[0], args) do
          #{old_method}(*args, &block)
            end
          end
          EOC
        end
      end
    end

    class Instrument

      MethodCall = Struct.new(:call_number, :backtrace, :file, :line, :context, :kind, :method, :thread)
      class Timing
        def initialize(start, finish)
          @start, @finish = start, finish
        end

        attr_reader :start, :finish

        def duration
          @duration ||= ((@finish - @start) * 1000).to_i
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

      def run(context="::", kind=:instance, called_at = caller[0], args=[], &blk)
        file, line, method = called_at.split(':')
        method = method.gsub(/^in|[^\w]+/, '') if method
        call_number = self.class.seq_number
        method_call = MethodCall.new(call_number, called_at, file, line, context, kind, method, Thread::current)

        start_time = Time.now
        start_event(method_call, args)
        result = blk.call      # execute the provided code block
        finish_event(method_call, args, start_time, result)
      end

      def collectors_for(method_call)
        probe = PackageDefinition.get_probe(method_call.context)
        collectors = probe.collectors([method_call.method, method_call.kind])
        collectors
      end

      def start_event(method_call, arguments)
        collectors_for(method_call).each do |collector|
          collector.before_detect(method_call, arguments)
        end
      end

      def finish_event(method_call, arguments, start_time, result)
        timing = Timing.new(start_time, Time.now)
        collectors_for(method_call).each do |collector|
          collector.after_detect(method_call, timing, arguments, result)
        end
      end

      def all_collectors
        @collectors ||= PackageDefinition.probes.map do |probe|
                            probe.all_collectors
                          end.flatten.uniq
      end

      def start(env)
        all_collectors.each do |collector|
          collector.request_start(env, @start)
        end
      end

      def finish(env, status, headers, body)
        @timing = Timing.new(@start, Time.now)
        @collectors.each do |collector|
          collector.request_finish(env, status, headers, body, @timing)
        end
      end

      def duration
        @timing.duration
      end
    end
  end
end
