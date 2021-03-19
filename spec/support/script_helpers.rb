

def check_scripts
  raise "Aborting test because script config is missing" unless SCRIPT_PATHS
  raise "Aborting test because script config is missing" unless SCRIPT_PATHS['activate_alarm']
  raise "Aborting test because script config is missing" unless SCRIPT_PATHS['deactivate_alarm']
end
