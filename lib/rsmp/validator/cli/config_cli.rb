require 'thor'
require_relative '../config_check'

module RSMP
  module Validator
    # CLI subcommands for validator configuration.
    class ConfigCLI < Thor
      namespace :config
      desc 'check PATH...', 'Validate rsmp-validator config files'
      method_option :mode, type: :string, aliases: '-m', default: 'auto',
                           enum: %w[auto site supervisor],
                           banner: 'Validator config mode: auto, site or supervisor'
      def check(*paths)
        if paths.empty?
          puts 'Error: config check requires at least one path'
          exit 1
        end

        valid = true
        paths.each do |path|
          RSMP::Validator::ConfigCheck.check_file(path, mode: options[:mode])
          puts 'OK'
        rescue RSMP::ConfigurationError => e
          valid = false
          puts "Error: #{e.message}"
        end

        exit 1 unless valid
      end
    end
  end
end
