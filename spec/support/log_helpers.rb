
LOG_PATH = 'log/validation.log'

# create log folder if it doesn't exist
FileUtils.mkdir_p 'log'


module LogHelpers
  def log_confirmation action, &block
    @site.log "Confirming #{action}", level: :test
    start_time = Time.now
    yield block
    delay = Time.now - start_time
    upcase_first = action.sub(/\S/, &:upcase)
    @site.log "#{upcase_first} confirmed after #{delay.to_i}s", level: :test
  end

  def log str
    File.open(LOG_PATH, 'a') do |file|
      file.puts str
    end
  end

  def cant_test err
    raise "Cannot run test: #{err}"
  end


  def abort_with_error error
    puts error.colorize(:red)
    exit
  end

end
