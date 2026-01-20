module Validator
  module StatusHelpers
    class SignalGroupSequenceHelper
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
  end
end
