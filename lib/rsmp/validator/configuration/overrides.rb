module RSMP
  module Validator
    module Configuration
      # Applies CLI overrides to both the validator config and embedded local node config.
      module Overrides
        def apply_cli_overrides!(raw_config)
          apply_core_version_override!(raw_config) if core_version_override
          apply_sxls_override!(raw_config) if sxls_override
        end

        private

        def apply_core_version_override!(raw_config)
          raw_config['core_version'] = core_version_override
          apply_local_core_version_override!(raw_config, core_version_override)
        end

        def apply_sxls_override!(raw_config)
          sxls = parse_sxls(sxls_override)
          raw_config['sxls'] = sxls
          apply_local_sxls_override!(raw_config, sxls)
        end

        def apply_local_core_version_override!(raw_config, version)
          case mode
          when :site
            apply_supervisor_site_override!(raw_config['local_supervisor'], 'core_version', version)
          when :supervisor
            raw_config['local_site']['core_version'] = version if raw_config['local_site'].is_a?(Hash)
          end
        end

        def apply_local_sxls_override!(raw_config, sxls)
          case mode
          when :site
            apply_supervisor_site_override!(raw_config['local_supervisor'], 'sxls', sxls)
          when :supervisor
            raw_config['local_site']['sxls'] = sxls if raw_config['local_site'].is_a?(Hash)
          end
        end

        def apply_supervisor_site_override!(local_supervisor, key, value)
          return unless local_supervisor.is_a?(Hash)

          local_supervisor['default'] ||= {}
          local_supervisor['default'][key] = value

          sites = local_supervisor['sites']
          return unless sites.is_a?(Hash)

          sites.each_value do |site_settings|
            site_settings[key] = value if site_settings.is_a?(Hash)
          end
        end
      end
    end
  end
end
