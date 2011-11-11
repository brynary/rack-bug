# Figure out what kind of app we're in front of.  For right now, we'll assume
# the answer is "Rails 3"
#
# TODO: Quickly so that it does drive me nuts: what I want to do here is have a
# class responsible for per-framework intrumentation, and an auto-instrument
# class method: run through registered subclasses, looking for one that says "I
# recognize this" and then run it.  First one wins.  Should have a nice "I need
# to come before..." method.


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

