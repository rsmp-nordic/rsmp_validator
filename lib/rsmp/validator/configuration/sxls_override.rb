module RSMP
  module Validator
    module Configuration
      # Parses CLI SXL overrides.
      module SxlsOverride
        def apply_auto_node_overrides!(raw_config)
          raw_config['core_version'] = core_version_override if mode == :site && core_version_override
          apply_auto_node_sxls_override!(raw_config) if sxls_override
        end

        def apply_auto_node_sxls_override!(raw_config)
          sxls = parse_sxls(sxls_override)
          if mode == :supervisor
            raw_config['sites'] ||= {}
            raw_config['sites']['default'] ||= {}
            raw_config['sites']['default']['sxls'] = sxls
          else
            raw_config['sxls'] = auto_site_sxls(sxls, raw_config['sxls'])
          end
        end

        # An explicit list opts the auto site into hint testing. Keep its initial
        # version and allowed alternatives while the tester requests one version.
        def auto_site_sxls(overrides, configured)
          return overrides unless configured.is_a?(Hash)

          overrides.to_h do |name, version|
            [name, configured[name].is_a?(Array) ? configured[name] : version]
          end
        end

        def parse_sxls(value)
          abort_with_error 'Invalid --sxls value, expected name:version,...' if value.empty?

          value.split(',', -1).each_with_object({}) do |item, memo|
            parts = item.split(':', -1)
            unless parts.length == 2 && parts.none?(&:empty?)
              abort_with_error "Invalid --sxls item #{item.inspect}, expected name:version"
            end

            name, version = parts
            memo[name] = version
          end
        end
      end
    end
  end
end
