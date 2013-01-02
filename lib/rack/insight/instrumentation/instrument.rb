require 'rack/insight/instrumentation/backstage'
require 'rack/insight/logging'

module Rack::Insight
  module Instrumentation
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

      include Rack::Insight::Instrumentation::Backstage

      include Rack::Insight::Logging

      def run(object, context="::", kind=:instance, called_at = caller[0], method = "<unknown>", args=[], &blk)
        file, line, rest = called_at.split(':')
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
        if verbose(:debug)
          logger.debug do
            "Probe chain for: #{method_call.context} #{method_call.kind} #{method_call.method}:\n  #{collectors.map{|col| col.class.name}.join(", ")}"
          end
        end
        collectors
      end

      def start_event(method_call, arguments)
        if verbose(:debug)
          logger.debug{ "Starting event: #{method_call.context} #{method_call.kind} #{method_call.method}" }
        end

        collectors_for(method_call).each do |collector|
          collector.before_detect(method_call, arguments)
        end
      end

      def finish_event(method_call, arguments, start_time, result)
        timing = Timing.new(@start, start_time, Time.now)
        if verbose(:debug)
          logger.debug{ "Finishing event: #{method_call.context} #{method_call.kind} #{method_call.method}" }
        end
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
