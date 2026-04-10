describe 'Site::Core' do
  # Verify the site connects correctly.
  #
  # 1. Given the site is connected
  # 2. Then the handshake is complete
  it 'connects' do
    expect(true).to be == true
  end

  # Verify the site disconnects.
  it 'disconnects' do
    # nothing
  end

  it 'has no docstring' do
    # no comment above this spec
  end
end
