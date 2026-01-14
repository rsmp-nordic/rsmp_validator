# frozen_string_literal: true

module Validator
  module StatusHelpers
    # Match a specific status response or update
    class S0033Matcher < RSMP::StatusMatcher
      attr_accessor :state

      def initialize(want, request_id:, state: nil)
        super(want)
        @request_id = request_id
        @state = state
        @latest_state = nil
      end

      # Match a status value against a matcher
      def match?(item)
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

      # look through a status message to find state
      # updates for a specific priority request
      def find_request_state(list)
        priority = list.find { |prio| prio['r'] == @request_id }
        priority['s'] if priority
      end
    end

    class SignalPriorityRequestHelper < RSMP::Queue
      include Validator::StatusHelpers
      include Validator::CommandHelpers

      def initialize(site, component:, signal_group_id:, timeout:, task:)
        super(site,
          filter: RSMP::Filter.new(
            type: 'StatusUpdate',
            ingoing: true,
            outgoing: false,
            component: component
          ),
          task: task
        )
        @site = site
        @component = component
        @signal_group_id = signal_group_id
        @request_id = SecureRandom.uuid[0..3]
        @matcher = S0033Matcher.new({ 'cCI' => 'S0033', 'q' => 'recent' }, request_id: @request_id)
        @subscribe_list = [{ 'sCI' => 'S0033', 'n' => 'status', 'uRt' => '0' }]
        @subscribe_list.map! { |item| item.merge!('sOc' => true) } if use_sOc?(@site)
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

      def request(
        level: 7,
        eta: 2,
        vehicleType: 'car'
      )
        command_list = build_command_list(:M0022, :requestPriority, {
                                            requestId: @request_id,
                                            signalGroupId: @signal_group_id,
                                            type: 'new',
                                            level: level,
                                            eta: eta,
                                            vehicleType: vehicleType
                                          })
        @site.send_command @component, command_list
      end

      def request_unrelated(
        level: 7,
        eta: 2,
        vehicleType: 'car'
      )
        command_list = build_command_list(:M0022, :requestPriority, {
                                            requestId: SecureRandom.uuid[0..3],
                                            signalGroupId: @signal_group_id,
                                            type: 'new',
                                            level: level,
                                            eta: eta,
                                            vehicleType: vehicleType
                                          })
        @site.send_command @component, command_list
      end

      def cancel
        command_list = build_command_list :M0022, :requestPriority, {
          requestId: @request_id,
          type: 'cancel'
        }
        @site.send_command @component, command_list
      end

      def expect(state)
        @matcher.state = state
        wait_for_message timeout: @timeout
      rescue RSMP::TimeoutError
        raise RSMP::TimeoutError, "Priority request did not reach state #{state} within #{@timeout}s"
      end

      private

      def accept_message?(message)
        super && get_items(message).any? { |item| @matcher.match?(item) }
      end

      def start
        start_receiving
        @site.subscribe_to_status @component, @subscribe_list
      end

      def stop
        @site.unsubscribe_to_status @component, @unsubscribe_list
        stop_receiving
      end

      def get_items(message)
        message.attributes['sS'] || []
      end
    end
  end
end
