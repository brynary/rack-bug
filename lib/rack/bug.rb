require "rack"

module Rack::Bug
  autoload :Options,                "rack/bug/options"
  autoload :Panel,                  "rack/bug/panel"
  autoload :PanelApp,               "rack/bug/panel_app"
  autoload :ParamsSignature,        "rack/bug/params_signature"
  autoload :Render,                 "rack/bug/render"
  autoload :Toolbar,                "rack/bug/toolbar"

  # Panels
  autoload :ActiveRecordPanel,      "rack/bug/panels/active_record_panel"
  autoload :CachePanel,             "rack/bug/panels/cache_panel"
  autoload :LogPanel,               "rack/bug/panels/log_panel"
  autoload :MemoryPanel,            "rack/bug/panels/memory_panel"
  autoload :RailsInfoPanel,         "rack/bug/panels/rails_info_panel"
  autoload :RedisPanel,             "rack/bug/panels/redis_panel"
  autoload :RequestVariablesPanel,  "rack/bug/panels/request_variables_panel"
  autoload :SQLPanel,               "rack/bug/panels/sql_panel"
  autoload :TemplatesPanel,         "rack/bug/panels/templates_panel"
  autoload :TimerPanel,             "rack/bug/panels/timer_panel"

  VERSION = File.read(File.join(File.dirname(__FILE__), "..", "..", "VERSION")).strip

  class SecurityError < StandardError
  end

  def self.enable
    Thread.current["rack-bug.enabled"] = true
  end

  def self.disable
    Thread.current["rack-bug.enabled"] = false
  end

  def self.enabled?
    Thread.current["rack-bug.enabled"] == true
  end

  def self.new(*args, &block)
    Toolbar.new(*args, &block)
  end
end