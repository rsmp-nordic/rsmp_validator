RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::StatusHelpers

  describe 'Subscription' do
    # Check that we can *subscribe* to status messages.
    # The test subscribes to S0001 (signal group status), because
    # it will usually change once per second, but otherwise the choice
    # is arbitrary as we simply want to check that
    # the subscription mechanism works.
    #
    # 1. subscribe
    # 1. check that we receive a status update with a predefined time
    # 1. unsubscribe

    it 'can be turned on and off for S0001' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Subscribe to status and wait for update"
        component = Validator.get_config('main_component')

        status_list = [{'sCI'=>'S0001','n'=>'signalgroupstatus','uRt'=>'1'}]
        status_list.map! { |item| item.merge!('sOc' => true) } if use_sOc?(site)

         site.subscribe_to_status component, status_list, collect!: {
          timeout: Validator.get_config('timeouts','status_update')
        }
      ensure
        unsubscribe_list = status_list.map { |item| item.slice('sCI','n') }
        site.unsubscribe_to_status component, unsubscribe_list
      end
    end
  end
end
