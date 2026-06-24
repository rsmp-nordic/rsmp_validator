# Internal sus config: runs unit/integration tests in test/validator/
# No RSMP connection or reactor setup needed here.
#
# Usage:
#   bundle exec sus                  # runs test/validator/**/*.rb
#   bundle exec sus test/validator
#
# To run conformance tests against real equipment, use the rsmp-validator executable:
#   bundle exec rsmp-validator run test/site

def test_paths
  Dir.glob('test/validator/**/*.rb', base: @root)
end
