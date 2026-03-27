module Validator
  module Helpers
    module Input
      include Status

      def force_input_and_confirm(site, input:, value:)
        site.force_input(input: input, status: 'True', value: value)
        digit = (value == 'True' ? '1' : '0')

        # Index is 1-based, convert to 0-based for regex
        wait_for_status(
          site,
          "input #{input} to be #{value}",
          [
            { 'sCI' => 'S0003', 'n' => 'inputstatus', 's' => /^.{#{input - 1}}#{digit}/ }
          ]
        )
      end

      def switch_input(site, indx)
        site.set_input(input: indx.to_s, status: 'True')

        # Index is 1-based, convert to 0-based for regex
        wait_for_status(
          site,
          "input #{indx} to be True",
          [
            { 'sCI' => 'S0003', 'n' => 'inputstatus', 's' => /^.{#{indx - 1}}1/ }
          ]
        )

        site.set_input(input: indx.to_s, status: 'False')
        wait_for_status(
          site,
          "input #{indx} to be False",
          [{ 'sCI' => 'S0003', 'n' => 'inputstatus', 's' => /^.{#{indx - 1}}0/ }]
        )
      end
    end
  end
end
