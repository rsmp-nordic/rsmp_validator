# Automatically starts a local RSMP site to be tested
# This is used when testing the validator or RSMP gem itself
# The site runs inside the same Async reactor context as the tester

require_relative 'auto_node'

class Validator::AutoSite < Validator::AutoNode

  protected

  def node_type
    'site'
  end

  # Build a local RSMP site that will be tested
  # The site configuration comes from the auto_config loaded from validator.yaml
  def build_node
    # Determine the site class based on type
    klass = case config['type']
    when 'tlc'
      RSMP::TLC::TrafficControllerSite
    else
      RSMP::Site
    end

    # Create the site with the auto_config settings
    klass.new(
      site_settings: config,
      logger: Validator.logger
    )
  end
end
