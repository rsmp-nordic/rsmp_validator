describe 'Site::Core' do
  describe 'Connection Sequence' do
    include Validator::Helpers::Handshake

    # Verify the connection sequence when using rsmp core 3.1.1
    #
    # 1. Given the site is connected and using core 3.1.1
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.1
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.1' do
      skip 'requires core == 3.1.1' unless Validator.core_matches?('3.1.1')
      check_sequence '3.1.1'
    end

    # Verify the connection sequence when using rsmp core 3.1.2
    #
    # 1. Given the site is connected and using core 3.1.2
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.2
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.2' do
      skip 'requires core == 3.1.2' unless Validator.core_matches?('3.1.2')
      check_sequence '3.1.2'
    end

    # Verify the connection sequence when using rsmp core 3.1.3
    #
    # 1. Given the site is connected and using core 3.1.3
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.3
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.3' do
      skip 'requires core == 3.1.3' unless Validator.core_matches?('3.1.3')
      check_sequence '3.1.3'
    end

    # Verify the connection sequence when using rsmp core 3.1.4
    #
    # 1. Given the site is connected and using core 3.1.4
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.4
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.4' do
      skip 'requires core == 3.1.4' unless Validator.core_matches?('3.1.4')
      check_sequence '3.1.4'
    end

    # Verify the connection sequence when using rsmp core 3.1.5
    #
    # 1. Given the site is connected and using core 3.1.5
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.5
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.5' do
      skip 'requires core == 3.1.5' unless Validator.core_matches?('3.1.5')
      check_sequence '3.1.5'
    end

    # Verify the connection sequence when using rsmp core 3.2
    #
    # 1. Given the site is connected and using core 3.2
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.5
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.2' do
      skip 'requires core == 3.2' unless Validator.core_matches?('3.2')
      check_sequence '3.2'
    end

    # Verify the connection sequence when using rsmp core 3.2.1
    #
    # 1. Given the site is connected and using core 3.2.1
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.5
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.2.1' do
      skip 'requires core == 3.2.1' unless Validator.core_matches?('3.2.1')
      check_sequence '3.2.1'
    end

    # Verify the connection sequence when using rsmp core 3.2.2
    #
    # 1. Given the site is connected and using core 3.2.2
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.5
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.2.2' do
      skip 'requires core == 3.2.2' unless Validator.core_matches?('3.2.2')
      check_sequence '3.2.2'
    end

    # Verify the connection sequence when using rsmp core 3.3.0
    #
    # 1. Given the site is connected and using core 3.3.0
    # 2. When handshake messages are sent and received
    # 3. Then ComponentList should be exchanged before application traffic
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.3.0' do
      skip 'requires core == 3.3.0' unless Validator.core_matches?('3.3.0')
      check_sequence '3.3.0'
    end
  end
end
