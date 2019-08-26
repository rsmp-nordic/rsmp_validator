RSpec.describe "RSMP Site" do	
extend RSpec::WithParams::DSL

	context 'when connecting' do
		with_params(
			[:version,:expected_sequence],
			["3.1.1", [
				['in','Version'],
				['out','MessageAck'],
				['out','Version'],
				['in','MessageAck'],
				['in','Watchdog'],
				['out','MessageAck'],
				['out','Watchdog'],
				['in','MessageAck']
			]],
			["3.1.2", [
				['in','Version'],
				['out','MessageAck'],
				['out','Version'],
				['in','MessageAck'],
				['in','Watchdog'],
				['out','MessageAck'],
				['out','Watchdog'],
				['in','MessageAck']
			]],
			["3.1.3", [
				['in','Version'],
				['out','MessageAck'],
				['out','Version'],
				['in','MessageAck'],
				['in','Watchdog'],
				['out','MessageAck'],
				['out','Watchdog'],
				['in','MessageAck'],
				['in','AggregatedStatus'],
				['out','MessageAck']
			]],
			["3.1.4", [
				['in','Version'],
				['out','MessageAck'],
				['out','Version'],
				['in','MessageAck'],
				['in','Watchdog'],
				['out','MessageAck'],
				['out','Watchdog'],
				['in','MessageAck'],
				['in','AggregatedStatus'],
				['out','MessageAck']
			]],
		) do
			it 'exchanges correct connection sequence' do
				SupervisorRunner.without_site do |task|
					supervisor = RSMP::Supervisor.new supervisor_settings: {
						'rsmp_versions' =>  [version],
						'log' => { 'active' => false }
					}
					supervisor.start
					remote_site = SupervisorRunner.instance.wait_for_site supervisor
			
					items = supervisor.archive.capture task, with_message: true, num: expected_sequence.size, timeout: 1, from: 0
					got = items.map { |item| item[:message] }.map { |message| [message.direction.to_s, message.type] }
					expect(got).to eq(expected_sequence)
					expect(remote_site.ready?).to be true
					supervisor.stop
					task.yield
				end
			end
		end

	end
end
