
# this class is used to store versions in a class variable
# where the filter inspect() methods can read them
class Validator::Restrict
  @@versions = {}
  def self.versions
    @@versions
  end
end

def setup_filters rspec_config
  Validator::Restrict.versions['core'] = Validator.config.dig('restrict_testing','core_version')
  Validator::Restrict.versions['sxl'] = Validator.config.dig 'restrict_testing','sxl_version' 

  core_version = Validator::Restrict.versions['core']
  sxl_version = Validator::Restrict.versions['sxl']

  # enable filtering by sxl version using e.g. sxl: '>=1.0.7'
  # the sxl version defined in the site config is mathed against the sxl tag
  # Gem::Requirement and Gem::Version classed are used to do the version matching,
  # but this otherwise has nothing to do with Gems, we're just using 
  # the version match utilities
  if sxl_version
    sxl_version = Gem::Version.new sxl_version
    filter = -> (v) {
      !Gem::Requirement.new(v).satisfied_by?(sxl_version)
    }
    # redefine the inspect method on our proc object,
    # so we get more useful display of the filter option when we
    # run rspec on the command line  
    def filter.inspect
      "[unless relevant for #{Validator::Restrict.versions['sxl']}]"
    end
    rspec_config.filter_run_excluding sxl: filter 
  end

  # enable filtering by rsmp core version using e.g. rsmp: '>=3.1.2'
  # the rsmp version defined in the site config is mathed against the rsmp tag
  # Gem::Requirement and Gem::Version classed are used to do the version matching,
  # but this otherwise has nothing to do with Gems, we're just using
  # the version match utilities
  if core_version
    core_version = Gem::Version.new core_version
    filter = -> (v) {
      !Gem::Requirement.new(v).satisfied_by?(core_version)
    }
    # redefine the inspect method on our proc object,
    # so we get more useful display of the filter option when we
    # run rspec on the command line  
    def filter.inspect
      "[unless relevant for #{Validator::Restrict.versions['core']}]"
    end
    rspec_config.filter_run_excluding rsmp: filter
  end
end
