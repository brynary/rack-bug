module Rack::Insight
  module Logging
    VERBOSITY = {
      :debug => Logger::DEBUG,
      :high => Logger::INFO,
      :med => Logger::WARN,
      :low => Logger::ERROR,
      # Silent can be used with unless instead of if.  Example:
      #   logger.info("some message") unless app.verbose(:silent)
      :silent => Logger::FATAL
    }

    def logger
      Rack::Insight::Config.logger
    end
    module_function :logger

    # max_level is confusing because the 'level' of output goes up (and this is what max refers to)
    # when the integer value goes DOWN
    def verbose(max_level = false)
      #logger.unknown "Rack::Insight::Config.verbosity: #{Rack::Insight::Config.verbosity} <= max_level: #{VERBOSITY[max_level]}" #for debugging the logger
      return false if (!Rack::Insight::Config.verbosity) # false results in Exactly Zero output!
      return true if (Rack::Insight::Config.verbosity == true) # Not checking truthy because need to check against max_level...
      # Example: if configured log spam level is high (1) logger should get all messages that are not :debug (0)
      #          so, if a log statement has if verbose(:low) (:low is 3)
      #          1 <= 3 # true => Message sent to logger
      #          then, if a log statement has if verbose(:debug) (:debug is 0)
      #          1 <= 0 # false => Nothing sent to logger
      return true if Rack::Insight::Config.verbosity <= (VERBOSITY[max_level]) # Integers!
    end
    module_function :verbose
  end
end
