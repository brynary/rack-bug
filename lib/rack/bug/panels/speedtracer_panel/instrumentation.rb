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
    build_tracing_wrappers((class << @const; self; end), '#{self.name}::', *methods_names)
  end

  def trace_methods(*methods)
    build_tracing_wrappers(@const, '#{self.class.name}#', *methods)
  end

  module TraceRunner
    def trace_run(context = "::", called_at=caller[1], args=[])
      tracer = Thread.current['st.tracer']
      result = nil
      if tracer.nil?
        Rails.logger.debug{"No tracer in thread - #{context} / #{called_at}"}
        result = yield
      else
        tracer.run(context, called_at, args){ result = yield }
      end
      result
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

  def build_tracing_wrappers(target, context, *methods)
    safe_method_names(methods).each do |method_name, old_method|
      next if @traced.has_key?(method_name)
      @traced[method_name] = true


      #TODO: nicer chaining
      target.class_eval <<-EOC, __FILE__, __LINE__
      alias #{old_method} #{method_name}
      include TraceRunner
      def #{method_name}(*args, &block)

        trace_run("#{context}", caller(0)[0], args) do
          #{old_method}(*args, &block)
        end
      end
      EOC
    end
  end
end
