require "rack/bug/speedtracer/duck-puncher"

find_constant("ActionView::Template"){|avt| avt.trace_methods :render_template}

find_constant("ActiveRecord::Base") do |ar_b| 
  ar_b.trace_class_methods :find, :all, :first, :last, :count, :delete_all
  ar_b.trace_methods :save, :save!, :destroy, :delete
end

find_constant("ActionController::Base") do |ac_b|
  ac_b.trace_methods :process, :render
end

