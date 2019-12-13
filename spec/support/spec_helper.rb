require 'rsmp'
require_relative 'test_site'
require_relative 'test_supervisor'


RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

include RSpec

VALIDATOR_CONFIG = YAML.load_file 'config/validator.yaml' rescue {}
RSMP_CONFIG = YAML.load_file VALIDATOR_CONFIG['rsmp_config_path'] rescue {}
LOG_CONFIG = YAML.load_file VALIDATOR_CONFIG['log_config_path'] rescue {}
SECRETS = YAML.load_file('config/secrets.yaml') rescue {}

#sugar
SUPERVISOR_CONFIG = RSMP_CONFIG['supervisor'] rescue {}
SITE_CONFIG = SUPERVISOR_CONFIG['sites'].values.first rescue {}
MAIN_COMPONENT = SITE_CONFIG['components'].keys.first rescue {}


puts "Using test config #{VALIDATOR_CONFIG['rsmp_config_path']}"
