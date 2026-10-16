module RSMP
  module Validator
    module Configuration
      # Parses CLI SXL overrides.
      module SxlsOverride
        def apply_auto_node_overrides!(raw_config)
          apply_auto_node_sxls_override!(raw_config) if sxls_override
        end

        def apply_auto_node_sxls_override!(raw_config)
          sxls = parse_sxls(sxls_override)
          if mode == :supervisor
            raw_config['sites'] ||= {}
            raw_config['sites']['default'] ||= {}
            raw_config['sites']['default']['sxls'] = sxls
          else
            raw_config['sxls'] = sxls
          end
        end

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
