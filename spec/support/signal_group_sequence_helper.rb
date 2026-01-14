# frozen_string_literal: true

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
        @latest = states
        @num_groups = states.size
        states.each_char.with_index do |state, i|
          pos = @pos[i]                 # current pos
          if pos                        # if the group has already started:
            current = @sequence[pos] # get current state
            if state != current # did the state change?
              if pos == @sequence.length - 1 # at end?
                expected = @sequence[-1] # if at end, expected to stay there
              else
                next_pos = pos + 1
                expected = @sequence[next_pos] # if not at end expected to move to the next state in sequence
              end
              if state != expected      # did it go to, or stay in, the expected state?
                return "Group #{i} changed from #{current} to #{state}, must go to #{expected}"
              end

              @pos[i] = next_pos        # move position
            end
          elsif state == @sequence[0] # if the group didn't start yet:
            @pos[i] = 0 # look for start of sequence
          end
        end
        :ok
      end
    end
  end
end
