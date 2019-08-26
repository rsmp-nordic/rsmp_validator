RSpec.describe "RSMP Site" do	
extend RSpec::WithParams::DSL

	with_params(
		[:value,:response],
		["Rainbows!","Rainbows!"],
		[198234,198234],
		[0.0523,0.0523],
		[-0.0523,0.0523],
		["æåøÆÅØ","ææåøÆÅØ"],
		["-_,.-/\"*§!{#€%&/()=?`}","-_,.-/\"*§!{#€%&/()=?`}"],
		["",""],
		[nil,nil],
	) do
		it 'responds to command request' do
			SupervisorRunner.with_site do |task,site|
				site.send_command 'AA+BBCCC=DDDEE002', [{"cCI":"MA104","n":"message","cO":"","v":"Rainbows!"}]
				response = site.wait_for_command_response component: 'AA+BBCCC=DDDEE002', timeout: 1
				expect(response).to be_a(RSMP::CommandResponse)
				expect(response.attributes["cId"]).to eq("AA+BBCCC=DDDEE002")
				expect(response.attributes["rvs"]).to eq([{"age"=>"recent", "cCI"=>"MA104", "n"=>"message", "v"=>"Rainbows!"}])
			end
		end

	end
end
