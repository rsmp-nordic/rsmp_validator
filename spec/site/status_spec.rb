RSpec.describe "RSMP site status" do
  include StatusHelpers

  it 'S0001 signal group status', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "signal group status",
      { S0001: [:signalgroupstatus, :cyclecounter, :basecyclecounter, :stage] }
  end

  it 'S0002 detector logic status', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "detector logic status",
      { S0002: [:detectorlogicstatus] }
  end

  it 'S0003 input status', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "input status",
      { S0003: [:inputstatus] }
  end

  it 'S0004 output status', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "output status",
      { S0004: [:outputstatus] }
 end

  it 'S0005 traffic controller starting', sxl: '>=1.0.7'  do |example|
    request_status_and_confirm "traffic controller starting (true/false)",
      { S0005: [:status] }
  end

  it 'S0006 emergency stage', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "emergency stage status",
      { S0006: [:status,:emergencystage] }
 end

  it 'S0007 controller switched on (dark mode=off)', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "controller switch on (dark mode=off)",
      { S0007: [:status,:intersection] }
  end

  it 'S0008 manual control', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "manual control status",
      { S0008: [:status,:intersection] }
  end

  it 'S0009 fixed time control', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "fixed time control status",
      { S0009: [:status,:intersection] }
  end

  it 'S0010 isolated control', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "isolated control status",
      { S0010: [:status,:intersection] }
  end

  it 'S0011 yellow flash', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "yellow flash status",
      { S0011: [:status,:intersection] }
  end

  it 'S0012 all red', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "all-red status",
      { S0012: [:status,:intersection] }
  end

  it 'S0013 police key', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "police key",
      { S0013: [:status] }
  end

  it 'S0014 current time plan', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "current time plan",
      { S0014: [:status] }
  end

  it 'S0015 current traffic situation'  do |example|
    request_status_and_confirm "current traffic situation",
      { S0015: [:status] }
  end

  it 'S0016 number of detector logics', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "number of detector logics",
      { S0016: [:number] }
  end

  it 'S0017 number of signal groups', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "number of signal groups",
      { S0017: [:number] }
  end

  it 'S0018 number of time plans', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "number of time plans",
      { S0018: [:number] }
  end

  it 'S0019 number of traffic situations', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "number of traffic situations",
      { S0019: [:number] }
  end

  it 'S0020 control mode', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "control mode",
      { S0020: [:controlmode,:intersection] }
  end

  it 'S0021 manually set detector logic', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "manually set detector logics",
      { S0021: [:detectorlogics] }
  end

  it 'S0022 list of time plans', sxl: '>=1.0.13'  do |example|
    request_status_and_confirm "list of time plans",
      { S0022: [:status] }
  end

  it 'S0023 command table', sxl: '>=1.0.13' do |example|
    request_status_and_confirm "command table",
      { S0023: [:status] }
  end

  it 'S0024 offset time', sxl: '>=1.0.13'  do |example|
    request_status_and_confirm "offset time",
      { S0024: [:status] }
  end

  it 'S0025 time-of-green/time-of-red', sxl: '>=1.0.13' do |example|
    request_status_and_confirm "time-of-green/time-of-red",
      { S0025: [
          :minToGEstimate,
          :maxToGEstimate,
          :likelyToGEstimate,
          :ToGConfidence,
          :minToREstimate,
          :maxToREstimate,
          :likelyToREstimate
      ] },
      COMPONENT_CONFIG['signal_group'].keys.first
  end

  it 'S0026 week time table', sxl: '>=1.0.13'  do |example|
    request_status_and_confirm "week time table",
      { S0026: [:status] }
  end

  it 'S0027 time tables', sxl: '>=1.0.13'  do |example|
    request_status_and_confirm "command table",
      { S0027: [:status] }
  end

  it 'S0028 cycle time', sxl: '>=1.0.13' do |example|
    request_status_and_confirm "cycle time",
      { S0028: [:status] }
  end

  it 'S0029 forced input status', sxl: '>=1.0.13' do |example|
    request_status_and_confirm "forced input status",
      { S0029: [:status] }
  end

  it 'S0030 forced output status', sxl: '>=1.0.15' do |example|
    request_status_and_confirm "forced output status",
      { S0030: [:status] }
  end

  it 'S0031 trigger level sensitivity for loop detector', sxl: '>=1.0.15' do |example|
    request_status_and_confirm "trigger level sensitivity for loop detector",
      { S0031: [:status] }
  end

  it 'S0091 operator logged in/out OP-panel', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "operator logged in/out OP-panel",
      { S0091: [:status, :user] }
  end

  it 'S0092 operator logged in/out web-interface', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "operator logged in/out web-interface",
      { S0092: [:status, :user] }
  end

  it 'S0095 version of traffic controller', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "version of traffic controller",
      { S0095: [:status] }
  end

  it 'S0096 current date and time', sxl: '>=1.0.7'  do |example|
    request_status_and_confirm "current date and time",
      { S0096: [
        :year,
        :month,
        :day,
        :hour,
        :minute,
        :second,
      ] }
  end

  it 'S0097 version of traffic program', sxl: '>=1.0.15' do |example|
    request_status_and_confirm "version of traffic program",
      { S0097: [:version,:hash] }
  end

  # S0098 missing

  it 'S0201 traffic counting: number of vehicles'  do |example|
    request_status_and_confirm "traffic counting: number of vehicles",
      { S0201: [:starttime,:vehicles] },
      COMPONENT_CONFIG['detector_logic'].keys.first
  end

  it 'S0202 traffic counting: vehicle speed', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "traffic counting: vehicle speed",
      { S0202: [:starttime,:speed] },
      COMPONENT_CONFIG['detector_logic'].keys.first
  end

  it 'S0203 traffic counting: occupancy'  do |example|
    request_status_and_confirm "traffic counting: occupancy",
      { S0203: [:starttime,:occupancy] },
      COMPONENT_CONFIG['detector_logic'].keys.first
  end

  it 'S0204 traffic counting: classification', sxl: '>=1.0.7' do |example|
    request_status_and_confirm "traffic counting: classification",
      { S0204: [
          :starttime,
          :P,
          :PS,
          :L,
          :LS,
          :B,
          :SP,
          :MC,
          :C,
          :F
      ] },
      COMPONENT_CONFIG['detector_logic'].keys.first
  end

  it 'S0205 traffic counting: number of vehicles', sxl: '>=1.0.14'  do |example|
    request_status_and_confirm "traffic counting: number of vehicles",
      { S0205: [:start,:vehicles] }
  end

  it 'S0206 traffic counting: vehicle speed', sxl: '>=1.0.14' do |example|
    request_status_and_confirm "traffic counting: vehicle speed",
      { S0206: [:start,:speed] }
  end

  it 'S0207 traffic counting: occupancy', sxl: '>=1.0.14' do |example|
    request_status_and_confirm "traffic counting: occupancy",
      { S0207: [:start,:occupancy] }
  end

  it 'S0208 traffic counting: classification', sxl: '>=1.0.14' do |example|
    request_status_and_confirm "traffic counting: classification",
      { S0208: [
          :start,
          :P,
          :PS,
          :L,
          :LS,
          :B,
          :SP,
          :MC,
          :C,
          :F
      ] }
  end
end
