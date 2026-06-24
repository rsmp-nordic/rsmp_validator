require_relative 'lib/rsmp/validator/version'

Gem::Specification.new do |spec|
  spec.name = 'rsmp-validator'
  spec.version = RSMP::Validator::VERSION
  spec.authors = ['RSMP Nordic']
  spec.email = []

  spec.summary = 'RSMP compliance test suite'
  spec.description = 'Validates RSMP sites and supervisors using the sus test framework'
  spec.homepage = 'https://github.com/rsmp-nordic/rsmp_validator'
  spec.license = 'MIT'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.required_ruby_version = '>= 3.1'

  spec.files = Dir[
    'lib/**/*',
    'test/site/**/*',
    'test/supervisor/**/*',
    'config/**/*',
    'schemas/**/*',
    'exe/*'
  ]

  spec.bindir = 'exe'
  spec.executables = ['rsmp-validator']

  spec.add_dependency 'rsmp', '>= 0.44.0'
  %w[activesupport colorize sus sus-fixtures-async thor].each { |name| spec.add_dependency name }
end
