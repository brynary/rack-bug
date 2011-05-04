require "rack/bug/panels/speedtracer_panel/instrumentation"

# Figure out what kind of app we're in front of.  For right now, we'll assume 
# the answer is "Rails 3"


Rack::Bug::SpeedTracerPanel::Instrumentation::connect do |inst|
  inst.instrument("ActionView::Rendering") do |avt|
    avt.trace_methods :render
  end

  inst.instrument("ActionView::Partials::PartialRenderer") do |avppr|
    avppr.trace_methods :render
  end

  inst.instrument("ActiveRecord::Base") do |ar_b| 
    ar_b.trace_class_methods :find, :all, :first, :last, :count, :delete_all
    ar_b.trace_methods :save, :save!, :destroy, :delete
  end

  inst.instrument("ActionController::Base") do |ac_b|
    ac_b.trace_methods :process, :render
  end
end

