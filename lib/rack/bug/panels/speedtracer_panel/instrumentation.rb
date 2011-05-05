require 'rack/bug/panels/speedtracer_panel'

class Rack::Bug::SpeedTracerPanel
  class Instrumentation
    @instruments = Hash.new do |h,k|
      h[k] = Instrument.new(k)
    end

    class << self
      def get_instrument(const)
        return @instruments[const]
      end

      def connect
        yield(self.new)
      end
    end

    def instrument(name)
      parts = name.split("::")
      begin
        const = parts.inject(Kernel) do |namespace, part|
          namespace.const_get(part)
        end
      rescue NameError => ex
        warn "Couldn't find #{name}"
        return nil
      end
      instrument = self.class.get_instrument(const)
      yield(instrument) if block_given?
      return instrument
    end

  end

  class Instrument
    def initialize(const)
      @const = const
      @traced = {}
      @unsafe_names = (@const.public_instance_methods(true) + 
                       @const.protected_instance_methods(true) + 
                       @const.private_instance_methods(true)).sort.uniq
    end

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

    module Interpose
    end

    module TraceRunner
      def trace_run(context = "::", called_at=caller[1], args=[])
        tracer = Thread.current['st.tracer']
        result = nil
        if tracer.nil?
          Rails.logger.debug{"No tracer in thread"}
          result = yield
        else
          tracer.run(context, called_at, args){ result = yield }
        end
        result
      end
    end

    def build_tracing_wrappers(target, interpose_module, context, *methods)
      p [target, context, methods]
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
              p self.class => self.class.ancestors

              super
            end
          end
        end
      end

      return nil
    end
  end
end
