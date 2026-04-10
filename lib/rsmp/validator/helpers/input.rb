module Validator
  module Helpers
    # Helper methods for testing RSMP input/output functionality.
    module Input
      include Status

      def force_input_and_confirm(site_proxy, input:, value:)
        site_proxy.force_input(input: input, status: 'True', value: value)
        digit = (value == 'True' ? '1' : '0')

        wait_for_status(
          site_proxy,
          "input #{input} to be #{value}",
          [
            { 'sCI' => 'S0003', 'n' => 'inputstatus', 's' => /^.{#{input - 1}}#{digit}/ }
          ]
        )
      end

      def switch_input(site_proxy, indx)
        site_proxy.set_input(input: indx.to_s, status: 'True')

        wait_for_status(
          site_proxy,
          "input #{indx} to be True",
          [
            { 'sCI' => 'S0003', 'n' => 'inputstatus', 's' => /^.{#{indx - 1}}1/ }
          ]
        )

        site_proxy.set_input(input: indx.to_s, status: 'False')
        wait_for_status(
          site_proxy,
          "input #{indx} to be False",
          [{ 'sCI' => 'S0003', 'n' => 'inputstatus', 's' => /^.{#{indx - 1}}0/ }]
        )
      end
    end
  end
end
