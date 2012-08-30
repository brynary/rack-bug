module Rack::Insight


  #Variant of the Speed Tracer Panel that performs a nearly complete profile of
  #all code called during a request.  Note that this will slow overall response
  #time by several orders of magnitude, and may return more data than
  #SpeedTracer is prepared to display
  class ProfilingSpeedTracer < SpeedTracer
    def before(env)
      super
      tracer = env['st.tracer']
      Kernel::set_trace_func proc {|event, file, line, name, binding,classname|
        case event
        when "c-call", "call"
          methodname = classname ? "" : classname
          methodname += name.to_s
          tracer.start_event(file, line, name, classname || "", "")
        when "c-return", "return"
          tracer.finish_event
        end
      }
    end

    def after(env, status, headers, body)
      Kernel::set_trace_func(nil)
      super
    end
  end
end
