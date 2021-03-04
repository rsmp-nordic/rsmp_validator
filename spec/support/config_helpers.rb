validator_config = YAML.load_file 'config/validator.yaml'
raise "Error: File config/validator.yaml is missing" unless validator_config

rsmp_config_path = validator_config['rsmp_config_path'] || 'config/ruby.yaml'
RSMP_CONFIG = YAML.load_file rsmp_config_path
puts "Using test config #{rsmp_config_path}"

if validator_config['log_config_path']
  LOG_CONFIG = YAML.load_file validator_config['log_config_path'] 
else
  LOG_CONFIG = {}
end

SECRETS = load_secrets 'config/secrets.yaml'

#sugar
SUPERVISOR_CONFIG = RSMP_CONFIG['supervisor'] rescue {}
puts "Warning: #{rsmp_config_path} supervisor settings is missing or empty" if SUPERVISOR_CONFIG == {}

SITE_CONFIG = SUPERVISOR_CONFIG['sites'].values.first rescue {}
puts "Warning: #{rsmp_config_path} sites settings is missing or empty" if SITE_CONFIG == {}

COMPONENT_CONFIG = SITE_CONFIG['components'] rescue {}
puts "Warning: #{rsmp_config_path} components settings is missing or empty" if COMPONENT_CONFIG == {}


MAIN_COMPONENT = COMPONENT_CONFIG['main'].keys.first rescue {}
puts "Warning: #{rsmp_config_path} main component settings is missing or empty" if MAIN_COMPONENT == {}


SCRIPT_PATHS = RSMP_CONFIG['scripts']
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

# check recommended configs
required = [
  'scripts'
]
required.each do |key|
  puts "Warning: Config '#{key}' is missing from #{rsmp_config_path}" unless RSMP_CONFIG[key]
end


# check required configs
required = [
  'connect_timeout',
  'ready_timeout',
  'subscribe_timeout',
  'status_update_rate',
  'alarm_timeout',
  'shutdown_timeout'
]
required.each do |key|
  raise "Config '#{key}'' is missing from #{rsmp_config_path}" unless RSMP_CONFIG[key]
end


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

  setup_filters config
end
