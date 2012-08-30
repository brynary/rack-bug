module Rack::Insight::Instrumentation
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

      def clear_collectors
        all_collectors.clear
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
end
