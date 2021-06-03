# get config path
validator_config = YAML.load_file 'config/validator.yaml'
raise "Error: File config/validator.yaml is missing" unless validator_config

# load config
rsmp_config_path = validator_config['rsmp_config_path']
VALIDATOR_CONFIG = YAML.load_file rsmp_config_path
puts "Using test config #{rsmp_config_path}"

# log path
LOG_CONFIG = VALIDATOR_CONFIG['log_config_path'] rescue {}


# secrets
# first look for secrets specific to rsmp_config_path, e.g.
# if rsmp_config_path is 'rsmp_gem.yaml', look for 'secrets_rsmp_gem.yaml'
# if not found, use the generic 'secrets.yaml'
secrets_name = File.basename(rsmp_config_path,'.yaml')
secrets_path = "config/secrets_#{secrets_name}.yaml"
secrets_path = 'config/secrets.yaml' unless File.exist?(secrets_path)
SECRETS = load_secrets(secrets_path)


# rsmp supervisor config
# pick certains elements from the validator config
# 
want = ['sxl','intervals','timeouts','components','rsmp_versions']
guest_settings = VALIDATOR_CONFIG.select { |key| want.include? key }
SUPERVISOR_CONFIG = {
  'port' => VALIDATOR_CONFIG['port'],
  'max_sites' => 1,
  'guest' => guest_settings
}

# components
COMPONENT_CONFIG = VALIDATOR_CONFIG['components'] rescue {}
puts "Warning: #{rsmp_config_path} 'components' settings is missing or empty" if COMPONENT_CONFIG == {}

MAIN_COMPONENT = COMPONENT_CONFIG['main'].keys.first rescue {}
puts "Warning: #{rsmp_config_path} 'main' component settings is missing or empty" if MAIN_COMPONENT == {}

# timeouts
TIMEOUTS_CONFIG = VALIDATOR_CONFIG['timeouts'] rescue {}
puts "Warning: #{rsmp_config_path} 'timeouts' settings is missing or empty" if TIMEOUTS_CONFIG == {}

[
  'connect',
  'ready',
  'status_response',
  'status_update',
  'subscribe',
  'command',
  'command_response',
  'alarm',
  'disconnect',
  'shutdown'
].each do |key|
  raise "Config 'timeouts/#{key}' is missing from #{rsmp_config_path}" unless TIMEOUTS_CONFIG[key]
end


# timeouts
ITEMS_CONFIG = VALIDATOR_CONFIG['items'] rescue {}


# scripts
SCRIPT_PATHS = SUPERVISOR_CONFIG['scripts']
if SCRIPT_PATHS
  puts "Warning: Script path for activating alarm is missing or empty" if SCRIPT_PATHS['activate_alarm'] == {}
  unless File.exist? SCRIPT_PATHS['activate_alarm']
    puts "Warning: Script at #{SCRIPT_PATHS['activate_alarm']} for activating alarm is missing"
  end
  puts "Warning: Script path for deactivating alarm is missing or empty" if SCRIPT_PATHS['deactivate_alarm'] == {}
  unless File.exist? SCRIPT_PATHS['deactivate_alarm']
    puts "Warning: Script at #{SCRIPT_PATHS['deactivate_alarm']} for deactivating alarm is missing"
  end
end



# configure RSpec
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # write to the validator log when each test start
  config.before(:example) do |example|
    log "\nRunning test #{example.metadata[:location]} - #{example.full_description}".colorize(:light_black)
  end

  # filtering by core/sxl version
  setup_filters config
end
