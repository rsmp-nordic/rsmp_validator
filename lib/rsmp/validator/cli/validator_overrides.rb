module RSMP
  module Validator
    # Applies CLI overrides to global validator settings for a single run.
    module ValidatorOverrides
      OVERRIDE_ACCESSORS = {
        core_version: :core_version_override,
        sxls: :sxls_override,
        site_config_path: :site_config_path,
        supervisor_config_path: :supervisor_config_path,
        auto_site_config_path: :auto_site_config_path,
        auto_supervisor_config_path: :auto_supervisor_config_path
      }.freeze

      def apply_overrides(overrides)
        overrides.each do |name, value|
          RSMP::Validator.public_send("#{OVERRIDE_ACCESSORS.fetch(name)}=", value)
        end
      end

      def clear_overrides(overrides)
        overrides.each_key do |name|
          RSMP::Validator.public_send("#{OVERRIDE_ACCESSORS.fetch(name)}=", nil)
        end
        RSMP::Validator.config_path = nil
      end
    end
  end
end
