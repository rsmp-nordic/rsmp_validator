# frozen_string_literal: true

module Validator
  module Log
    INDENT = '> '

    def self.log(action, **options)
      Validator.log "> #{action}", **options
    end

    def self.log_block(action, **options)
      @log_indentation ||= 0
      previous_log_indentation = @log_indentation
      Validator.log "> #{INDENT * @log_indentation}#{action}", **options
      @log_indentation += 1
      yield
    rescue StandardError
      Validator.log "  #{INDENT * previous_log_indentation}#{action}: ERROR", level: :test
      raise
    rescue Async::TimeoutError
      Validator.log "  #{INDENT * previous_log_indentation}#{action}: TIMEOUT", level: :test
      raise RSMP::TimeoutError, "Timeout while #{action}"
    ensure
      @log_indentation = previous_log_indentation
    end

    # log the start of an action
    def log(action, **options)
      Validator::Log.log(action, **options)
    end

    # log the start and completion/error of a block of code
    def log_block(action, **options, &block)
      Validator::Log.log_block(action, **options, &block)
    end
  end
end
