module Validator::StatusHelpers
  class SequenceError < StandardError
  end

  class SequenceHelper
    def initialize sequence
      @pos = []
      @sequence = sequence
    end

    def done?
      @pos.any? && @pos.all? {|pos| pos == @sequence.length-1 }
    end

    def check states
      states.each_char.with_index do |state,i|
        pos = @pos[i]                 # current pos
        if pos                        # if the group has already started:
          current = @sequence[ pos ]  # the current state
          next_pos = pos + 1          # next pos is current + 1
          expected = @sequence[ next_pos ]  # the next position of the group
          if state != current         # did the state change?
            if state != expected      # did it go to the expected next state?
              raise SequenceError.new("Group #{i} at #{pos}:#{current} changed to #{state}, expected #{expected}")
            end
            @pos[i] = next_pos        # move position
          end
        else                          # if the group didn't start yet:
          if state == @sequence[0]    # look for start of sequence
            @pos[i] = 0               # start at pos 0
          end
        end
      end
    end
  end
end