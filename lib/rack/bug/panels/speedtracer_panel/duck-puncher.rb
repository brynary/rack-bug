require 'rack/bug/speedtracer'

module Kernel
  def find_constant(name)
    parts = name.split("::")
    begin
      const = parts.inject(Kernel) do |namespace, part|
        namespace.const_get(part)
      end
    rescue NameError => ex
      warn "Couldn't find #{name}"
      return nil
    end
    yield(const) if block_given?
    return const
  end

#        trace_run(method_name, context, caller[1], *args) do
  def trace_run(context = "::", called_at=caller[1], args=[])
    tracer = Thread.current['st.tracer']
    result = nil
    if tracer.nil?
      Rails.logger.debug{"Null trace"}
      result = yield
    else
      tracer.run(context, called_at, args){ result = yield }
    end
    result
  end
end

class Rack::Bug::SpeedTracer
  class << self
    def safe_method_names(mod, method_names)
      unsafe_names = (mod.public_instance_methods(true) + 
        mod.protected_instance_methods(true) + 
        mod.private_instance_methods(true)).sort.uniq

      method_names.map do |name|
        name = name.to_s
        prefix = "0"
        hidden_name = ["_", prefix, name].join("_")
        while unsafe_names.include?(hidden_name)
          prefix = prefix.next
          hidden_name = ["_", prefix, name].join("_")
        end

        unsafe_names << hidden_name
        [name, hidden_name]
      end
    end
  end
end

class Module
  def trace_class_methods(*methods_names)
    (class << self; self; end).build_tracing_wrappers('#{self.name}::', *methods_names)
  end

  def trace_methods(*methods)
    build_tracing_wrappers('#{self.class.name}#', *methods)
  end

  def build_tracing_wrappers(context, *methods)
    @traced ||= {}

    Rack::Bug::SpeedTracer::safe_method_names(self, methods).each do |method_name, old_method|
      next if @traced.has_key?(method_name)
      @traced[method_name] = true

      alias_method old_method, method_name

      self.class_eval <<-EOC, __FILE__, __LINE__
      def #{method_name}(*args, &block)
        trace_run("#{context}", caller(0)[0], args) do
          #{old_method}(*args, &block)
        end
      end
      EOC
    end
  end
end
