require 'thor'
require_relative '../config_check'

module RSMP
  module Validator
    # CLI subcommands for validator configuration.
    class ConfigCLI < Thor
      namespace :config
      desc 'check PATH...', 'Validate config files or directories (recursively)'
      method_option :mode, type: :string, aliases: '-m', default: 'auto',
                           enum: %w[auto site supervisor],
                           banner: 'Validator config mode: auto, site or supervisor'
      method_option :core, type: :string, desc: 'Override RSMP Core version for this check'
      method_option :sxls, type: :string, desc: 'Override SXL versions as name:version,...'
      def check(*paths)
        if paths.empty?
          puts 'Error: config check requires at least one path'
          exit 1
        end

        results = paths.map { |path| check_path(path) }
        exit 1 unless results.all?
      end

      private

      def check_path(path)
        results = config_files(path).map { |file| check_file(file) }
        results.all?
      rescue RSMP::ConfigurationError => e
        puts "Error: #{path}: #{e.message}"
        false
      end

      def config_files(path)
        return [path] unless File.directory?(path)

        files = Dir.glob(File.join(path, '**', '*')).select do |file|
          File.file?(file) && %w[.yaml .yml].include?(File.extname(file).downcase) &&
            !file.downcase.end_with?('_secrets.yaml', '_secrets.yml')
        end
        raise RSMP::ConfigurationError, 'No test config files found' if files.empty?

        files
      end

      def check_file(path)
        ConfigCheck.check_file(path, mode: options[:mode], core: options[:core], sxls: options[:sxls])
        puts "OK: #{path}"
        true
      rescue RSMP::ConfigurationError => e
        puts "Error: #{path}: #{e.message}"
        false
      end
    end
  end
end
