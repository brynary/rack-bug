require 'rack/insight/config'

module Rack::Insight
  module Logging

    def verbosity
      Rack::Insight::Config.verbosity
    end
    module_function :verbosity

    def logger
      Rack::Insight::Config.logger
    end
    module_function :logger

    # max_level is confusing because the 'level' of output goes up (and this is what max refers to)
    # when the integer value goes DOWN
    def verbose(max_level = false)
      #logger.unknown "Rack::Insight::Logging.verbosity: #{Rack::Insight::Logging.verbosity} <= max_level: #{VERBOSITY[max_level]}" #for debugging the logger
      return false if (!verbosity) # false results in Exactly Zero output!
      return true if (verbosity == true) # Not checking truthy because need to check against max_level...
      # Example: if configured log spam level is high (1) logger should get all messages that are not :debug (0)
      #          so, if a log statement has if verbose(:low) (:low is 3)
      #          1 <= 3 # true => Message sent to logger
      #          then, if a log statement has if verbose(:debug) (:debug is 0)
      #          1 <= 0 # false => Nothing sent to logger
      return true if verbosity <= (Rack::Insight::Config::VERBOSITY[max_level]) # Integers!
    end
    module_function :verbose
  end
end
