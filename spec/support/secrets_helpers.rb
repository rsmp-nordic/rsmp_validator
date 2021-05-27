
def load_secrets secrets_path
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