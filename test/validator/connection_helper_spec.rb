require_relative '../../lib/rsmp/validator'

describe RSMP::Validator::Helpers::Connection do
  def connection_helper
    @connection_helper ||= Class.new do
      include RSMP::Validator::Helpers::Connection
    end.new
  end

  it 'classifies closed RSMP connections separately from unexpected exceptions' do
    errors = [
      RSMP::NotReady.new('Cannot send StatusRequest: connection is disconnected'),
      RSMP::DisconnectError.new('Connection was closed'),
      EOFError.new('Secure RSMP peer closed connection'),
      IOError.new('Secure RSMP transport is closed'),
      IOError.new('Cannot send StatusRequest: connection transport is closed'),
      Errno::ECONNRESET.new
    ]

    expect(errors.all? { |error| connection_helper.send(:connection_lost?, error) }).to be == true
    expect(connection_helper.send(:connection_lost?, IOError.new('disk read failed'))).to be == false
  end

  it 'reports malformed secure frames separately from connection loss' do
    error = RSMP::Secure::FrameError.new('Truncated secure frame payload')

    expect(connection_helper.send(:secure_protocol_failure?, error)).to be == true
    expect(connection_helper.send(:connection_lost?, error)).to be == false
  end

  it 'preserves the cause and backtrace in connection-loss reports' do
    error = RSMP::NotReady.new('Cannot send StatusRequest: connection is disconnected')
    error.set_backtrace(['/tmp/connection.rb:1'])
    wrapped = RSMP::Validator::Helpers::Connection::ConnectionLost.new(error)
    expected_message =
      'RSMP connection was lost while the test was running: Cannot send StatusRequest: connection is disconnected'

    expect(wrapped.message).to be == expected_message
    expect(wrapped.backtrace).to be == ['/tmp/connection.rb:1']
  end
end
