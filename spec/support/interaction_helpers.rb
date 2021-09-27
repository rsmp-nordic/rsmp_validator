module Validator
  def ask_user site, question, accept:''
    async_stdin = Async::IO::Stream.new( Async::IO::Generic.new($stdin) )
    pointing = "\u{1f449}"
    print "#{pointing} " + question.colorize(:color => :light_magenta) + " "
    site.log "Asking user for input: #{question}", level: :test
    response = async_stdin.gets.chomp
    if response == accept
      site.log "OK from user", level: :test
    else
      site.log "Test skipped by user", level: :test
      expect(response).to eq(accept), "Test skipped by user"
    end
  end
end
