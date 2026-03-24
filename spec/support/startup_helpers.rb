module Validator
  module StartupHelpers
    def verify_startup_sequence
      status_list = [{ 'sCI' => 'S0001', 'n' => 'signalgroupstatus' }]
      subscribe_list = convert_status_list(status_list).map { |item| item.merge 'uRt' => 0.to_s }
      subscribe_list.map! { |item| item.merge!('sOc' => true) } if @site.use_soc?

      unsubscribe_list = convert_status_list(status_list)
      component = Validator.get_config('main_component')
      timeout = Validator.get_config('timeouts', 'startup_sequence')
      collector = RSMP::StatusCollector.new @site, status_list, timeout: timeout
      sequencer = Validator::StatusHelpers::SignalGroupSequenceHelper.new Validator.get_config('startup_sequence')
      states = nil

      collector_task = @task.async do
        log 'Verifying startup sequence'
        collector.collect do |_message, item| # listen for status messages
          next unless item

          states = item['s']
          handle_startup_sequence_item(states, sequencer, collector)
        end
      end

      # let block take other actions, like activating yellow flash, change control mode, etc.
      yield

      # subscribe, so we start getting status updates
      @site.subscribe_to_status component, subscribe_list

      handle_startup_sequence_result(collector_task.wait, sequencer, collector, timeout)

      wait_for_status(
        'control mode to be startup',
        [{ 'sCI' => 'S0020', 'n' => 'controlmode', 's' => 'control' }]
      )
    ensure
      @site.unsubscribe_to_status component, unsubscribe_list # unsubscribe
    end

    private

    def handle_startup_sequence_item(states, sequencer, collector)
      status = sequencer.check(states)

      if status == :ok
        log "Startup sequence #{states}: OK"
        return collector.complete if sequencer.done?

        return false
      end

      log "Startup sequence #{states}: Fail"
      collector.cancel status
    end

    def handle_startup_sequence_result(result, sequencer, collector, timeout)
      case result
      when :ok
        log 'Startup sequence verified'
      when :timeout
        raise(
          "Startup sequence '#{sequencer.sequence}' didn't complete in #{timeout}s, " \
          "reached #{sequencer.latest}, #{sequencer.num_started} started, " \
          "#{sequencer.num_done} done"
        )
      when :cancelled
        raise "Startup sequence '#{sequencer.sequence}' not followed: #{collector.error}"
      end
    end
  end
end
