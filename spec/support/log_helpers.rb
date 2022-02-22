module Validator
  module LogHelpers

    # Run a block of code that validates some expectition,
    # and log when we start and log how long it took to complete
    def log_confirmation action, &block
      Validator.log "Confirming #{action}...", level: :test
      start_time = Time.now
      yield block
      delay = Time.now - start_time
      upcase_first = action.sub(/\S/, &:upcase)
      Validator.log "#{upcase_first} confirmed after #{delay.to_i}s √", level: :test
    rescue Async::TimeoutError => e
      raise RSMP::TimeoutError.new "Timeout while confirming #{action}"
    end
  end
end
