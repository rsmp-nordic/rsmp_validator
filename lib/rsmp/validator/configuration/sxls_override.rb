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
            apply_supervisor_site_overrides!(raw_config, 'sxls' => sxls)
          else
            raw_config['sxls'] = auto_site_sxls(sxls, raw_config)
          end
        end

        def apply_supervisor_site_overrides!(supervisor, overrides)
          return unless supervisor.is_a?(Hash)

          defaults = supervisor['default']
          defaults.merge!(overrides) if defaults.is_a?(Hash)
          sites = supervisor['sites']
          return unless sites.is_a?(Hash)

          sites.each_value { |site| site.merge!(overrides) if site.is_a?(Hash) }
        end

        # Legacy Core can retry with a version hint. Core 3.3 selects SXLs in
        # one exchange, so advertise the requested version first when available.
        def auto_site_sxls(overrides, raw_config)
          configured = raw_config['sxls']
          return overrides unless configured.is_a?(Hash)

          overrides.to_h do |name, version|
            versions = configured[name]
            next [name, version] unless versions.is_a?(Array)

            versions = [version] | versions if raw_config['core_version'] == '3.3.0' && versions.include?(version)
            [name, versions]
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
