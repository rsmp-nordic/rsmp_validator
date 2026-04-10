# frozen_string_literal: true

# specify alias and a describe with a comment docstring
describe 'Site::Core' do
  # A context with its own docstring.
  describe 'Connection Sequence' do
    specify 'uses specify alias' do
      # nothing
    end
  end
end
