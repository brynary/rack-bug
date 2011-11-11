
require 'dalli'

Dalli::Client.class_eval do
  def perform_with_insight(op, *args)
  end
end

alias_method_chain :perform, :insight

rescue NameError, LoadError
end
