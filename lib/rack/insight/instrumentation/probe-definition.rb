module Rack::Insight::Instrumentation
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
end
