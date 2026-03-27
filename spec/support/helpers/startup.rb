module Validator
  module Helpers
    module Startup
      include Status

      class SignalGroupSequence
        attr_reader :sequence, :latest

        def initialize(sequence)
          @pos = []
          @sequence = sequence
          @num_groups = 0
          @latest = nil
        end

        def num_started
          @pos.count { |v| !v.nil? }
        end

        def num_done
          @pos.count { |pos| pos == @sequence.length - 1 }
        end

        def done?
          num_done == @num_groups
        end

        def check(states)
          initialize_check(states)

          states.each_char.with_index do |state, group_index|
            position = @pos[group_index]
            error = if position
                      check_started_group(group_index, state,
                                          position)
                    else
                      check_not_started_group(group_index, state)
                    end
            return error if error
          end

          :ok
        end

        private

        def initialize_check(states)
          @latest = states
          @num_groups = states.size
        end

        def check_not_started_group(group_index, state)
          @pos[group_index] = 0 if state == @sequence[0]
          nil
        end

        def check_started_group(group_index, state, position)
          current = @sequence[position]
          return nil if state == current

          expected, next_position = expected_transition(position)
          return "Group #{group_index} changed from #{current} to #{state}, must go to #{expected}" if state != expected

          @pos[group_index] = next_position
          nil
        end

        def expected_transition(pos)
          last = @sequence.length - 1
          return [@sequence[last], last] if pos == last

          next_pos = pos + 1
          [@sequence[next_pos], next_pos]
        end
      end

      def wait_normal_control(site, timeout: Validator.get_config('timeouts', 'startup_sequence'))
        site.wait_for_normal_control(timeout: timeout)
      end

      def verify_startup_sequence(task, site)
        status_list = [{ 'sCI' => 'S0001', 'n' => 'signalgroupstatus' }]
        subscribe_list, unsubscribe_list = build_subscribe_lists(site, status_list)
        component = Validator.get_config('main_component')
        timeout = Validator.get_config('timeouts', 'startup_sequence')
        collector = RSMP::StatusCollector.new site, status_list, timeout: timeout
        sequencer = SignalGroupSequence.new Validator.get_config('startup_sequence')
        collector_task = start_sequence_collector(task, collector, sequencer)
        yield
        site.subscribe_to_status component, subscribe_list
        handle_startup_sequence_result(collector_task.wait, sequencer, collector, timeout)
        wait_for_status(site, 'control mode to be startup',
                        [{ 'sCI' => 'S0020', 'n' => 'controlmode', 's' => 'control' }])
      ensure
        site.unsubscribe_to_status component, unsubscribe_list
      end

      private

      def build_subscribe_lists(site, status_list)
        subscribe_list = convert_status_list(status_list).map { |item| item.merge 'uRt' => 0.to_s }
        subscribe_list.map! { |item| item.merge!('sOc' => true) } if site.use_soc?
        [subscribe_list, convert_status_list(status_list)]
      end

      def start_sequence_collector(task, collector, sequencer)
        task.async do
          log 'Verifying startup sequence'
          collector.collect do |_message, item| # listen for status messages
            next unless item

            handle_startup_sequence_item(item['s'], sequencer, collector)
          end
        end
      end

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
end
