require_relative '../../../lib/rsmp/validator/buffer_replay_queue'

describe 'Site::Core' do
  describe 'Message Buffer' do
    let(:update_rate) { 1 }
    let(:outage_duration) { 2 * update_rate }
    let(:boundary_margin) { 0.25 * update_rate }
    let(:status_list) { [{ 'sCI' => 'S0001', 'n' => 'signalgroupstatus' }] }
    let(:component) { RSMP::Validator.get_config('main_component') }
    let(:collect_timeout) { RSMP::Validator.get_config('timeouts', 'status_update') }

    def subscribe_list(site_proxy)
      # Confirm that live updates are arriving before disconnecting.
      subscribe_list = status_list.map { |item| item.merge('uRt' => update_rate.to_s, 'q' => 'recent') }
      return subscribe_list unless site_proxy.tlc.use_soc?

      subscribe_list.map { |item| item.merge('sOc' => false) }
    end

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def subscribe_to_status(site_proxy)
      site_proxy.subscribe_to_status_and_collect(
        subscribe_list(site_proxy), component: component, within: collect_timeout
      ).value!
    end

    def simulate_outage
      closed_at = monotonic_now
      sleep outage_duration
      closed_at...monotonic_now
    end

    def queue_factory
      proc { |proxy| RSMP::Validator::BufferReplayQueue.new(proxy, component: component) }
    end

    def matching_statuses(message)
      message.attribute('sS').select do |status|
        status_list.any? { |wanted| wanted == status.slice('sCI', 'n') }
      end
    end

    def matching_status_update?(message)
      message.is_a?(RSMP::StatusUpdate) && !matching_statuses(message).empty?
    end

    def wait_for_buffered_update(queue, outage_window)
      timestamps = []
      Async::Task.current.with_timeout(collect_timeout) do
        loop do
          update = queue.wait_for_message!
          next unless matching_status_update?(update)

          timestamp = Time.parse(update.attribute('sTs'))
          timestamps << timestamp
          return [update, timestamps] if timestamp > outage_window.begin && timestamp < outage_window.end
        end
      end
    rescue RSMP::OperationError => e
      raise unless e.failure.code == :timeout

      [nil, timestamps]
    end

    def format_outage_window(window)
      first, last = [window.begin, window.end].map(&:getutc)
      same_date = first.strftime('%Y-%m-%d') == last.strftime('%Y-%m-%d')
      end_format = same_date ? '%H:%M:%S.%L' : '%Y-%m-%d %H:%M:%S.%L'
      "#{first.strftime('%Y-%m-%d %H:%M:%S.%L')}..#{last.strftime(end_format)} UTC"
    end

    def assert_message(buffered_message, outage_window)
      expectation = 'Received StatusUpdate timestamped within window'
      return expectation if buffered_message

      window_string = format_outage_window(outage_window)
      "#{expectation} #{window_string}"
    end

    # Verify that historical status data arrives after communication is restored.
    #
    # 1. Given the site is connected and a status subscription is active
    # 2. When communication is disrupted long enough for a status update to be due
    # 3. And communication is restored
    # 4. Then an update timestamped within the outage should arrive, even if fresh updates arrive first
    it 'sends status updates timestamped during the communication outage' do
      skip 'requires core >= 3.1.4' unless RSMP::Validator.core_matches?('>=3.1.4')

      with_site(:connected) { |site_proxy| subscribe_to_status(site_proxy) }
      offline = with_site(:disconnected) { simulate_outage }
      with_site(:connected, 'collect' => queue_factory) do |site_proxy|
        outage_window = site_proxy.collector.site_time_window(offline, boundary_margin)
        buffered_message, = wait_for_buffered_update(site_proxy.collector, outage_window)
        assert(buffered_message, assert_message(buffered_message, outage_window))
      ensure
        site_proxy.collector.stop
        site_proxy.unsubscribe_to_status! status_list, component: component
      end
    end

    # Verify that buffered status messages use quality "old" for core versions
    # where the core spec requires it.
    #
    # 1. Given the site is connected using core 3.2.0 or later
    # 2. And a status subscription is active
    # 3. When communication is disrupted and later restored
    # 4. Then buffered status values should have q=old
    it 'marks buffered status values as old for rsmp 3.2.0 and later' do
      skip 'requires core >= 3.2.0' unless RSMP::Validator.core_matches?('>=3.2.0')

      with_site(:connected) { |site_proxy| subscribe_to_status(site_proxy) }
      offline = with_site(:disconnected) { simulate_outage }
      with_site(:connected, 'collect' => queue_factory) do |site_proxy|
        outage_window = site_proxy.collector.site_time_window(offline, boundary_margin)
        buffered_update, = wait_for_buffered_update(site_proxy.collector, outage_window)
        assert(buffered_update, assert_message(buffered_update, outage_window))
        next unless buffered_update # skip the rest if no message was received

        assert(buffered_update.attribute('sS').all? { |status| status['q'] == 'old' }, 'Each status values have q=old')
      ensure
        site_proxy.collector.stop
        site_proxy.unsubscribe_to_status! status_list, component: component
      end
    end
  end
end
