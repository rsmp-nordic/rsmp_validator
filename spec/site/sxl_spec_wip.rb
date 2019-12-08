# Reads SXL in yaml format, and tests each status
# For each status, all argument names are tried in a separate rspec 'it' block,
# so failing cases are shown clearly.  

require 'yaml'

sxl = YAML.load(File.read(File.join(__dir__,'sxl.yaml')))

  def test &block
  	yield
  end


def test_status code, status
	status.each_pair do |n,options|
		test_status_part code, n, options
	end
end

def test_status_part code, n, options
	it "responds to #{code}/#{n}" do
		TestSite.connected do |task,supervisor,site|
			# send status request with one element
			timeout = 1
			component = 'C1'
			message, response = site.request_status component, [{'sCI'=>code,'n'=>n}], timeout
			# expect status response with one element, matching what we asked for
			expect(response).to be_a(RSMP::StatusResponse)
			expect(response.attributes["cId"]).to eq(component)
			sS_array = response.attributes["sS"]
			expect(sS_array.size).to eq( 1 )
			sS = sS_array.first
			expect(sS['sCI']).to eq( code )
			expect(sS['n']).to eq( n )

			# check that value conforms to sxl specification.
			# (this should be checked by JSON Schema validation, so remove?)
			s = sS['s']
			case options['type']
			when 'string'
				expect(s).to match(Regexp.new(options['format'])) if options['format']
			when 'integer'
				expect { s = s.to_i }.not_to raise_error
				expect(s).to be >= options['min'] if options['min']
				expect(s).to be <= options['max'] if options['max']
			when 'boolean'
			end
		end
	end
end

RSpec.describe "RSMP site status - " do
	sxl['status'].each_pair do |code, status|
		test_status code, status['arguments']
	end
end
