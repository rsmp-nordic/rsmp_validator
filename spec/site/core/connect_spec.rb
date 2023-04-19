RSpec.describe 'Site::Core' do
  describe 'Connection Sequence' do
    include Validator::HandshakeHelper

    # Verify the connection sequence when using rsmp core 3.1.1
    #
    # 1. Given the site is connected and using core 3.1.1
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.1
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.1', core: '3.1.1' do |example|
      check_sequence '3.1.1'
    end

    # Verify the connection sequence when using rsmp core 3.1.2
    #
    # 1. Given the site is connected and using core 3.1.2
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.2
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.2', core: '3.1.2' do |example|
      check_sequence '3.1.2'
    end

    # Verify the connection sequence when using rsmp core 3.1.3
    #
    # 1. Given the site is connected and using core 3.1.3
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.3
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.3', core: '3.1.3' do |example|
      check_sequence '3.1.3'
    end

    # Verify the connection sequence when using rsmp core 3.1.4
    #
    # 1. Given the site is connected and using core 3.1.4
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.4
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.4', core: '3.1.4' do |example|
      check_sequence '3.1.4'
    end

    # Verify the connection sequence when using rsmp core 3.1.5
    #
    # 1. Given the site is connected and using core 3.1.5
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.5
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.5',  core: '3.1.5' do |example|
      check_sequence '3.1.5'
    end

    # Verify the connection sequence when using rsmp core 3.2
    #
    # 1. Given the site is connected and using core 3.1.5
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.5
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.2',  core: '3.2' do |example|
      check_sequence '3.2'
    end
  end
end
