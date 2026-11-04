require 'securerandom'

module RSMP
  module Validator
    module Helpers
      module SignalPriority
        # Match a specific status response or update
        class S0033Matcher < RSMP::StatusMatcher
          def initialize(want, request_id:)
            super(want)
            @request_id = request_id
          end

          def match(item, state: nil)
            super_matched = super(item)
            return super_matched unless super_matched == true

            got = find_request_state item['s']
            !got.nil? && (state.nil? || got == state.to_s)
          end

          def find_request_state(list)
            priority = list.find { |prio| prio['r'] == @request_id }
            priority['s'] if priority
          end
        end

        # Helper queue for managing signal priority requests during tests.
        class RequestHelper < RSMP::Queue
          include RSMP::Validator::Helpers::Status

          def initialize(site_proxy, component:, signal_group_id:, timeout:)
            super(site_proxy,
                  filter: RSMP::Filter.new(
                    type: 'StatusUpdate',
                    ingoing: true,
                    outgoing: false,
                    component: component
                  ))
            @site_proxy = site_proxy
            @component = component
            @signal_group_id = signal_group_id
            @request_id = SecureRandom.uuid[0..3]
            @matcher = S0033Matcher.new({ 'sCI' => 'S0033', 'n' => 'status', 'q' => 'recent' }, request_id: @request_id)
            @subscribe_list = [{ 'sCI' => 'S0033', 'n' => 'status', 'uRt' => '0' }]
            @subscribe_list.map! { |item| item.merge!('sOc' => true) } if @site_proxy.tlc.use_soc?
            @unsubscribe_list = [{ 'sCI' => 'S0033', 'n' => 'status' }]
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
            @site_proxy.send_command!(command_list, component: @component)
          end

          def request_unrelated(level: 7, eta: 2, vehicle_type: 'car')
            command_list = RSMP::CommandList.new(:M0022, :requestPriority,
                                                 'requestId' => SecureRandom.uuid[0..3],
                                                 'signalGroupId' => @signal_group_id,
                                                 'type' => 'new',
                                                 'level' => level,
                                                 'eta' => eta,
                                                 'vehicleType' => vehicle_type).to_a
            @site_proxy.send_command!(command_list, component: @component)
          end

          def cancel
            command_list = RSMP::CommandList.new(:M0022, :requestPriority,
                                                 requestId: @request_id,
                                                 type: 'cancel').to_a
            @site_proxy.send_command!(command_list, component: @component)
          end

          def expect(state)
            # Consume in arrival order, retaining later updates for the next expectation.
            # One timeout covers the whole search, including non-matching updates.
            Async::Task.current.with_timeout(@timeout) do
              loop do
                message = wait_for_message!
                return message if get_items(message).any? { |item| @matcher.match(item, state: state) }
              end
            end
          rescue Async::TimeoutError => e
            RSMP::Result.failure(
              :timeout,
              message: "Signal priority request #{@request_id} did not become #{state} within #{@timeout}s",
              source: :timeout,
              cause: e
            ).value!
          end

          private

          def accept_message?(message)
            super && get_items(message).any? { |item| @matcher.match(item) }
          end

          def start
            start_receiving
            @site_proxy.subscribe_to_status! @subscribe_list, component: @component
          end

          def stop
            @site_proxy.unsubscribe_to_status! @unsubscribe_list, component: @component
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
