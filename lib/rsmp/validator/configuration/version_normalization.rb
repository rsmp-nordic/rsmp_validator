module RSMP
  module Validator
    module Configuration
      # Canonicalizes the versions used by filters and compliance metadata.
      # Embedded RSMP nodes retain configured legacy spellings for wire
      # compatibility; the rsmp gem normalizes them only for schema lookup.
      module VersionNormalization
        private

        def normalize_core_version!
          core_version = config['core_version'] || RSMP::Schema.latest_core_version
          config['core_version'] = canonical_core_version(core_version)
        end

        def canonical_core_version(core_version)
          core_version = RSMP::Schema.latest_core_version if core_version == 'latest'

          known_versions = RSMP::Schema.core_versions
          normalized = normalized_core_version(core_version, known_versions)
          return normalized.to_s if normalized

          abort_with_error "Unknown core version #{core_version}, must be one of [#{known_versions.join(', ')}]."
        end

        def normalized_core_version(core_version, known_versions)
          known_versions.map { |v| Gem::Version.new(v) }.sort.reverse.detect do |v|
            Gem::Requirement.new(core_version).satisfied_by?(v)
          end
        end

        def normalize_sxls!
          sxls = config['sxls']
          if sxls.nil?
            config['sxls'] = [{ 'name' => 'tlc', 'version' => RSMP::Schema.latest_version(:tlc) }]
            return
          end

          sxls.each do |sxl|
            name = sxl['name']
            abort_with_error 'SXL name cannot be core.' if name.to_s == 'core'

            sxl['version'] = canonical_sxl_version(name, sxl['version'])
          end
        end

        def canonical_sxl_version(name, version)
          normalized = RSMP::Schema.sanitize_version(version.to_s)
          RSMP::Schema.find_schema! name, normalized
          normalized
        rescue RSMP::Schema::UnknownSchemaError => e
          abort_with_error "Unknown SXL #{name} #{version}: #{e}"
        end
      end
    end
  end
end
