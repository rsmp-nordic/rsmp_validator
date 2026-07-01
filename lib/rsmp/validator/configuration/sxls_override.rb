module RSMP
  module Validator
    module Configuration
      # Parses CLI SXL overrides.
      module SxlsOverride
        def parse_sxls(value)
          value.split(',').each_with_object({}) do |item, memo|
            parts = item.split(':')
            abort_with_error "Invalid --sxls item #{item.inspect}, expected name:version" unless parts.length == 2

            name, version = parts
            memo[name] = version
          end
        end
      end
    end
  end
end
