require 'securerandom'

module RSMP
  module Validator
    module Helpers
      module SignalPriority
        # Match a specific status response or update
        class S0033Matcher < RSMP::StatusMatcher
          attr_accessor :state

          def initialize(want, request_id:, state: nil)
            super(want)
            @request_id = request_id
            @state = state
            @latest_state = nil
          end

          def match(item)
            super_matched = super
            if super_matched == true
              state = find_request_state item['s']
              if state == @state.to_s && state != @latest_state
                @latest_state = state
                true
              else
                false
              end
            else
              super_matched
            end
          end

          def find_request_state(list)
            priority = list.find { |prio| prio['r'] == @request_id }
            priority['s'] if priority
          end
        end

        # Helper queue for managing signal priority requests during tests.
        class RequestHelper < RSMP::Queue
          include RSMP::Validator::Helpers::Status

          def initialize(site_proxy, component:, signal_group_id:, timeout:, task:)
            super(site_proxy,
                  filter: RSMP::Filter.new(
                    type: 'StatusUpdate',
                    ingoing: true,
                    outgoing: false,
                    component: component
                  ),
                  task: task)
            @site_proxy = site_proxy
            @component = component
            @signal_group_id = signal_group_id
            @request_id = SecureRandom.uuid[0..3]
            @matcher = S0033Matcher.new({ 'cCI' => 'S0033', 'q' => 'recent' }, request_id: @request_id)
            @subscribe_list = [{ 'sCI' => 'S0033', 'n' => 'status', 'uRt' => '0' }]
            @subscribe_list.map! { |item| item.merge!('sOc' => true) } if @site_proxy.tlc.use_soc?
            @unsubscribe_list = [{ 'sCI' => 'S0033', 'n' => 'status' }]
            @got = []
            @timeout = timeout
          end

          def run
            start
            yield
          ensure
            stop
          end

          def request(level: 7, eta: 2, vehicle_type: 'car')
            command_list = RSMP::CommandList.new(:M0022, :requestPriority,
                                                 'requestId' => @request_id,
                                                 'signalGroupId' => @signal_group_id,
                                                 'type' => 'new',
                                                 'level' => level,
                                                 'eta' => eta,
                                                 'vehicleType' => vehicle_type).to_a
            @site_proxy.send_command(command_list, component: @component)
          end

          def request_unrelated(level: 7, eta: 2, vehicle_type: 'car')
            command_list = RSMP::CommandList.new(:M0022, :requestPriority,
                                                 'requestId' => SecureRandom.uuid[0..3],
                                                 'signalGroupId' => @signal_group_id,
                                                 'type' => 'new',
                                                 'level' => level,
                                                 'eta' => eta,
                                                 'vehicleType' => vehicle_type).to_a
            @site_proxy.send_command(command_list, component: @component)
          end

          def cancel
            command_list = RSMP::CommandList.new(:M0022, :requestPriority,
                                                 requestId: @request_id,
                                                 type: 'cancel').to_a
            @site_proxy.send_command(command_list, component: @component)
          end

          def expect(state)
            @matcher.state = state
            wait_for_message timeout: @timeout
          rescue RSMP::TimeoutError
            raise RSMP::TimeoutError, "Priority request did not reach state #{state} within #{@timeout}s"
          end

          private

          def accept_message?(message)
            super && get_items(message).any? { |item| @matcher.match(item) }
          end

          def start
            start_receiving
            @site_proxy.subscribe_to_status @subscribe_list, component: @component
          end

          def stop
            @site_proxy.unsubscribe_to_status @unsubscribe_list, component: @component
            stop_receiving
          end

          def get_items(message)
            message.attributes['sS'] || []
          end
        end
      end
    end
  end
end
