module Rack::Insight::Instrumentation
  module EigenClient

    def self.included(base)
      # Once a panel is probed self.is_probing should be set to true
      # Panels without tables override with self.has_table = false
      # check is_magic to wrap any functionality targeted at magic panels.
      base.send(:attr_accessor, :is_probing)
      base.send(:attr_accessor, :has_table)
      base.send(:attr_accessor, :table)
      base.send(:attr_accessor, :is_magic)
      base.send(:attr_accessor, :template_root)
    end

  end
end
