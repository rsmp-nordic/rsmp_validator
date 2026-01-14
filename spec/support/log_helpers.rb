module Validator
  module Log
    INDENT = '> '

    # log the start of an action
    def log(action)
      Validator.log "> #{action}", level: :test
    end

    # log the start and completion/error of a block of code
    def log_block(action, &block)
      @log_indentation ||= 0
      previous_log_indentation = @log_indentation
      Validator.log "> #{INDENT * @log_indentation}#{action}", level: :test
      Time.now
      @log_indentation += 1
      yield block
      # Validator.log "  #{INDENT*previous_log_indentation}#{action}: OK", level: :test
    rescue StandardError
      Validator.log "  #{INDENT * previous_log_indentation}#{action}: ERROR", level: :test
      raise
    rescue Async::TimeoutError
      Validator.log "  #{INDENT * previous_log_indentation}#{action}: TIMEOUT", level: :test
      raise RSMP::TimeoutError.new "Timeout while #{action}"
    ensure
      @log_indentation = previous_log_indentation
    end
  end
end
