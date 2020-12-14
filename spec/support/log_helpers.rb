module LogHelpers
  def log_confirmation action, &block
    @site.log "Confirming #{action}", level: :test
    start_time = Time.now
    yield block
    delay = Time.now - start_time
    upcase_first = action.sub(/\S/, &:upcase)
    @site.log "#{upcase_first} confirmed after #{delay.to_i}s", level: :test
  rescue RSpec::Expectations::ExpectationNotMetError => e
    @site.log "Could not confirm #{action}: #{e.to_s}", level: :test 
    raise e 
  end
end
