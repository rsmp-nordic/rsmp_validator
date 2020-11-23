require 'active_support/time'
require 'rsmp'
require 'fileutils'
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

def load_secrets path
	secrets_path = 'config/secrets.yaml'
	unless File.exist? secrets_path
		puts "Secrets file #{secrets_path} not found. Please add it and try again."
		exit
	end
	secrets = YAML.load_file(secrets_path)

	required_keys = ['security_codes']
	required_keys.each do |key|
		unless secrets[key]
			puts "The key '#{key}' is missing from #{secrets_path}. Please add it and try again."
			exit
		end
	end
	secrets
end

def ask_user site, question, accept:''
	pointing = "\u{1f449}"
	print "#{pointing} " + question.colorize(:color => :light_magenta) + " "
	site.log "Asking user for input: #{question}", level: :test
	response = ASYNC_STDIN.gets.chomp
	if response == accept
		site.log "OK from user", level: :test
	else
		site.log "Test skipped by user", level: :test
		expect(response).to eq(accept), "Test skipped by user"
	end
end

ASYNC_STDIN = Async::IO::Stream.new( Async::IO::Generic.new($stdin) )

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


# check required configs
required = [
	'connect_timeout',
	'ready_timeout',
	'command_timeout',
	'status_timeout',
	'subscribe_timeout',
	'alarm_timeout',
	'shutdown_timeout'
]
required.each do |key|
	raise "Config #{key} is missing from #{rsmp_config_path}" unless RSMP_CONFIG[key]
end


# create log folder if it doesn't exist
FileUtils.mkdir_p 'log'
