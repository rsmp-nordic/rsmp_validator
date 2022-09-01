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
        signal_group = Validator.config['components']['signal_group'].keys.first
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

    describe 'Status' do
      # Validate that signal priority status can be requested.
      #
      # 1. Given the site is connected
      # 2. When we request signal priority status
      # 3. Then we should receive an status update
      it 'can be requested with S0033', sxl: '>=1.1' do |example|
        Validator::Site.connected do |task,supervisor,site|
          request_status_and_confirm "signal group status",
            { S0033: [:status] }
        end
      end

      # Validate that signal priority status are send when priorty is requested
      #
      # 1. Given the site is connected
      # 2. And we subscribe to signal priority status updates
      # 3. When we send a signal priority request
      # 4. Then we should receive status updates
      # %. And the request should go through the correct states
      it 'can be subscribed to with S0033', sxl: '>=1.1' do |example|
        Validator::Site.connected do |task,supervisor,site|
          component = Validator.config['main_component']

          # subscribe
          log "Subscribing to signal priority request status updates"
          status_list = [{'sCI'=>'S0033','n'=>'status','uRt'=>'0','sOc'=>'True'}]
          site.subscribe_to_status component, status_list
         ensure
          # unsubcribe
          unsubscribe_list = status_list.map { |item| item.slice('sCI','n') }
          site.unsubscribe_to_status component, unsubscribe_list
        end
      end

      # Validate that signal priority status are send when priorty is requested
      #
      # 1. Given the site is connected
      # 2. And we subscribe to signal priority status
      # 2. When we send a signal priority request
      # 3. Then we should receive status updates
      it 'goes through received > acticated > completed', sxl: '>=1.1' do |example|
        Validator::Site.connected do |task,supervisor,site|
          component = Validator.config['main_component']

          # subscribe
          log "Subscribing to signal priority request status updates"
          status_list = [{'sCI'=>'S0033','n'=>'status','uRt'=>'0','sOc'=>'True'}]
          site.subscribe_to_status component, status_list

          # start collector
          request_id = SecureRandom.uuid()[0..3]    # make a message id
          num = 3
          states = []
          result = nil
          collector = nil
          collect_task = task.async do
            collector = RSMP::Collector.new(
              site,
              type: "StatusUpdate",
              num: num,
              timeout: 5,
              component: component
            )

            def search_for_request_state request_id, message
              message.attribute('sS').each do |status|
                if status['sCI'] == 'S0033' && status['n'] == 'status'
                  status['s'].each do |priority|
                    if priority['r'] == request_id  # our request?
                      state = priority['s']
                      log "Priority request reached state '#{state}'"
                      return state
                    end
                  end
                end
              end
              nil
            end

            result = collector.collect do |message|
              state = search_for_request_state request_id, message
              if state
                states << state
                :keep
              end
            end
          end

          # send request
          log "Sending signal priority request"
          signal_group = Validator.config['components']['signal_group'].keys.first
          command_list = build_command_list :M0022, :requestPriority, {
            requestId: request_id,
            signalGroupId: signal_group,
            type: 'new',
            level: 7,
            eta: 2,
            vehicleType: 'car'
          }
          site.send_command component, command_list

          # wait for collector to complete
          collect_task.wait
          expect(result).to eq(:ok)
          expect(collector.messages).to be_an(Array)
          expect(collector.messages.size).to eq(num)
          expected = ['received','activated', 'completed']
          expect(states).to eq(expected), "Expected states #{expected}, got #{states}"
        ensure
          # unsubcribe
          unsubscribe_list = status_list.map { |item| item.slice('sCI','n') }
          site.unsubscribe_to_status component, unsubscribe_list
        end
      end
    end
  end
end
