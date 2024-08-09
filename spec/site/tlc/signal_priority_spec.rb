RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::CommandHelpers
  include Validator::StatusHelpers

  describe "Signal Priority" do
    # Validate that a signal priority can be requested.
    #
    # 1. Given the site is connected
    # 2. When we send a signal priority request
    # 3. Then we should receive an acknowledgement
    it 'can be requested with M0022', sxl: '>=1.1' do |example|
      Validator::Site.connected do |task,supervisor,site|
        signal_group = Validator.get_config('components','signal_group').keys.first
        command_list = build_command_list :M0022, :requestPriority, {
          requestId: SecureRandom.uuid()[0..3],
          signalGroupId: signal_group,
          type: 'new',
          level: 7,
          eta: 10,
          vehicleType: 'car'
        }
        prepare task, site
        send_command_and_confirm @task, command_list,
          "Request signal priority for signal group #{signal_group}"
      end
    end

    # Validate that signal priority status can be requested.
    #
    # 1. Given the site is connected
    # 2. When we request signal priority status
    # 3. Then we should receive a status update
    it 'status can be fetched with S0033', sxl: '>=1.1' do |example|
      Validator::Site.connected do |task,supervisor,site|
        request_status_and_confirm site, "signal group status",
          { S0033: [:status] }
      end
    end

    # Validate that we can subscribe signal priority status
    #
    # 1. Given the site is connected
    # 2. And we subscribe to signal priority status updates
    # 4. Then we should receive an acknowledgement
    # 5. And we should reive a status updates
    it 'status can be subscribed to with S0033', sxl: '>=1.1' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        status_list = [{'sCI'=>'S0033','n'=>'status','uRt'=>'0'}]
        status_list.map! { |item| item.merge!('sOc' => true) } if use_sOc?(site)
        wait_for_status task, 'signal priority status', status_list
      end
    end

    # Validate that a signal priority completes when we cancel it.
    #
    # 1. Given the site is connected
    # 2. And we subscribe to signal priority status
    # 3. When we send a signal priority request
    # 4. Then the request state should become 'received'
    # 5. Then the request state should become 'activated'
    # 6. When we cancel the request
    # 7. Then the state should become 'completed'

    it 'state reaches completed', sxl: '>=1.1' do |example|
      Validator::Site.connected do |task,supervisor,site|
        sequence = ['received','activated','completed']
        timeout = Validator.get_config('timeouts','priority_completion')
        component = Validator.get_config('main_component')
        signal_group_id = Validator.get_config('components','signal_group').keys.first
        prio = Validator::StatusHelpers::SignalPriorityRequestHelper.new(
          site,
          component: component,
          signal_group_id: signal_group_id,
          timeout: timeout,
          task: task
        )

        prio.run do
          log "Before: Send an unrelated signal priority"
          #prio.request_unrelated

          log "Send signal priority request, wait for reception."
          prio.request

          log "After: Send an unrelated signal priority request"
          #prio.request_unrelated

          prio.expect :received
          log "Signal priority request was received, wait for activation."

          prio.expect :activated
          log "Signal priority request was activated, now cancel it and wait for completion."

          prio.cancel
          prio.expect :completed
          log "Signal priority request was completed."
        end
      end
    end

  end
end
