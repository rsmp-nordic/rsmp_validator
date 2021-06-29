
#LOG_PATH = 'log/validation.log'

# create log folder if it doesn't exist
#FileUtils.mkdir_p 'log'


module LogHelpers
  def log_confirmation action, &block
    Validator.log "Confirming #{action}", level: :test
    start_time = Time.now
    yield block
    delay = Time.now - start_time
    upcase_first = action.sub(/\S/, &:upcase)
    Validator.log "#{upcase_first} confirmed after #{delay.to_i}s", level: :test
  end

end
