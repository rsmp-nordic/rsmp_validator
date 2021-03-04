def setup_filters config
  # enable filtering by sxl version using e.g. sxl: '>=1.0.7'
  # the sxl version defined in the site config is mathed against the sxl tag
  # Gem::Requirement and Gem::Version classed are used to do the version matching,
  # but this otherwise has nothing to do with Gems, we're just using 
  # the version match utilities
  if SITE_CONFIG['sxl_version']
    sxl_version = Gem::Version.new SITE_CONFIG['sxl_version']
    filter = -> (v) {
      !Gem::Requirement.new(v).satisfied_by?(sxl_version)
    }
    # redefine the inspect method on our proc object,
    # so we get more useful display of the filter option when we
    # run rspec on the command line  
    def filter.inspect
      "[unless relevant for #{SITE_CONFIG['sxl_version'].to_s}]"
    end
    config.filter_run_excluding sxl: filter 
  end

  # enable filtering by rsmp core version using e.g. rsmp: '>=3.1.2'
  # the rsmp version defined in the site config is mathed against the rsmp tag
  # Gem::Requirement and Gem::Version classed are used to do the version matching,
  # but this otherwise has nothing to do with Gems, we're just using
  # the version match utilities
  if SITE_CONFIG['rsmp_versions']
    rsmp_versions = SITE_CONFIG['rsmp_versions'].map {|version| Gem::Version.new version }
    filter = -> (v) {
      exclude = true
      rsmp_versions.each do |version|
        if Gem::Requirement.new(v).satisfied_by?(version)
          exclude = false
          break
        end
      end
      exclude
    }
    # redefine the inspect method on our proc object,
    # so we get more useful display of the filter option when we
    # run rspec on the command line  
    def filter.inspect
      "[unless relevant for #{SITE_CONFIG['rsmp_versions'].join(', ')}]"
    end
    config.filter_run_excluding rsmp: filter
  end
end
