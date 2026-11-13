module RSMP
  module Validator
    # A single test scenario, with an ordered inbox shared by all of its waits.
    class Scenario # rubocop:disable Metrics/ClassLength -- Keep scenario exchange coordination together.
      attr_reader :id, :proxy

      def initialize(proxy, id, timeout: nil)
        @proxy = proxy
        @id = id
        @timeout = timeout
        @collecting = false
      end

      def collect
        raise ArgumentError, 'scenario needs a connected proxy' unless @proxy
        raise 'scenario is already collecting' if @collecting

        @queue = RSMP::Queue.new(@proxy, cancel: { invalid_message: true, disconnect: true,
                                                   missing_acknowledgement: true })
        @subscription = nil
        @subscription_code = nil
        @collecting = true
        begin
          @queue.start
          yield
        ensure
          @collecting = false
          @queue.stop
          @queue.clear
        end
      end

      def send_hint
        require_collection!
        @proxy.send_test_hint(@id)
      end

      # Returns Result::Success([CommandRequest, CommandResponse]). The normal
      # simulated-site handler sends the response; this method only observes it.
      def wait_for_command(code)
        wait_for_message('CommandRequest', direction: :in).and_then do |command|
          unless command.attribute('arg').map { |item| item['cCI'] }.uniq == [code]
            next unexpected_message(command, "CommandRequest for #{code}")
          end

          wait_for_message('CommandResponse', direction: :out).and_then do |response|
            if command_response_matches?(response, command, code)
              Result.success([command, response])
            else
              unexpected_message(response, "CommandResponse for #{code} on #{command.attribute('cId')}")
            end
          end
        end
      end

      def wait_for_ack(message, direction: :in)
        wait(:wait_for_ack, message, direction: direction)
      end

      # Returns Result::Success([StatusSubscribe, StatusUpdate]).
      def wait_for_subscribe(code)
        @subscription = nil
        wait(:wait_for_subscribe, code).and_then do |subscription|
          wait(:wait_for_status_update, code, direction: :out).and_then do |update|
            if subscription_update_matches?(update, subscription)
              @subscription = subscription
              @subscription_code = code
              Result.success([subscription, update])
            else
              unexpected_message(update, "StatusUpdate for #{code} on #{subscription.attribute('cId')}")
            end
          end
        end
      end

      # Wait for the supervisor to cancel the subscription returned by the last
      # successful wait_for_subscribe. The site acknowledges it normally.
      def wait_for_unsubscribe
        require_collection!
        raise 'wait_for_subscribe must succeed before waiting for unsubscribe' unless @subscription

        component = @subscription.attribute('cId')
        wait(:wait_for_unsubscribe, @subscription_code, component: component).and_then do |unsubscribe|
          if status_items(unsubscribe).sort == status_items(@subscription).sort
            @subscription = nil
            Result.success(unsubscribe)
          else
            unexpected_message(unsubscribe, 'StatusUnsubscribe matching the subscription')
          end
        end
      end

      def wait_for_message(type, direction:, component: nil)
        filter = RSMP::Filter.new(type: type, ingoing: direction == :in, outgoing: direction == :out,
                                  component: component)
        wait(:wait_for_message, filter: filter)
      end

      private

      def wait(method, *args, **options)
        require_collection!
        timeout = @timeout || Validator.get_config('timeouts', 'acknowledgement')
        result = @queue.public_send(method, *args, **options, timeout: timeout)
        return result unless result.failure? && result.failure.code == :timeout

        Result.failure(failure: result.failure.with(message: "Scenario #{@id}: #{result.failure.message}"))
      end

      def status_items(message)
        message.attribute('sS').map { |item| [item['sCI'], item['n']] }.uniq
      end

      def subscription_update_matches?(update, subscription)
        items = status_items(update)
        update.attribute('cId') == subscription.attribute('cId') &&
          !items.empty? && (items - status_items(subscription)).empty?
      end

      def command_response_matches?(response, command, code)
        response.attribute('cId') == command.attribute('cId') &&
          response.attribute('rvs').map { |item| item['cCI'] }.uniq == [code]
      end

      def require_collection!
        raise 'use scenario.collect before sending hints or waiting' unless @collecting
      end

      def unexpected_message(message, expected)
        Result.failure(:unexpected_message, message: "Scenario #{@id}: expected #{expected}",
                                            source: :peer, context: { message: message })
      end
    end
  end
end
