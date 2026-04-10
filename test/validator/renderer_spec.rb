# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative '../../lib/doc_gen/renderer'

RENDERER_FIXTURES = File.expand_path('../../fixtures/doc_gen', __dir__)

describe DocGen::Renderer do
	# Each `with` block gets its own temp directory.
	let(:tmp) { Dir.mktmpdir }
	after { FileUtils.rm_rf(tmp) }

	let(:simple_contexts)  { DocGen::Parser.parse_files(["#{RENDERER_FIXTURES}/simple.rb"]) }
	let(:nested_contexts)  { DocGen::Parser.parse_files(["#{RENDERER_FIXTURES}/nested.rb"]) }
	let(:deep_contexts)    { DocGen::Parser.parse_files(["#{RENDERER_FIXTURES}/deep.rb"]) }
	let(:edge_contexts)    { DocGen::Parser.parse_files(["#{RENDERER_FIXTURES}/edge_cases.rb"]) }

	def render(contexts) = DocGen::Renderer.render(contexts, output_dir: tmp)
	def read(path)       = File.read(File.join(tmp, path))

	with 'frontmatter — root context (depth 0)' do
		before { render(nested_contexts) }

		it 'sets parent to Test Suite' do
			expect(read('site_tlc_alarm.md')).to be =~ /^parent: Test Suite$/
		end

		it 'does not include grand_parent' do
			expect(read('site_tlc_alarm.md')).not.to be(:include?, 'grand_parent')
		end

		it 'sets has_children true when subcontexts exist' do
			expect(read('site_tlc_alarm.md')).to be =~ /^has_children: true$/
		end

		it 'sets layout to page' do
			render(simple_contexts)
			expect(read('site_core.md')).to be =~ /^layout: page$/
		end

		it 'sets title to the context name' do
			render(simple_contexts)
			expect(read('site_core.md')).to be =~ /^title: Site::Core$/
		end

		it 'sets has_toc to false' do
			render(simple_contexts)
			expect(read('site_core.md')).to be =~ /^has_toc: false$/
		end
	end

	with 'frontmatter — depth-1 context' do
		before { render(nested_contexts) }

		it 'sets parent to root name' do
			expect(read('site_tlc_alarm/alarm.md')).to be =~ /^parent: Site::Tlc::Alarm$/
		end

		it 'sets grand_parent to Test Suite' do
			expect(read('site_tlc_alarm/alarm.md')).to be =~ /^grand_parent: Test Suite$/
		end

		it 'sets has_children false when no subcontexts' do
			expect(read('site_tlc_alarm/alarm.md')).to be =~ /^has_children: false$/
		end

		it 'also applies to other depth-1 siblings' do
			expect(read('site_tlc_alarm/alarm_list.md')).to be =~ /^parent: Site::Tlc::Alarm$/
			expect(read('site_tlc_alarm/alarm_list.md')).to be =~ /^grand_parent: Test Suite$/
		end
	end

	with 'frontmatter — depth-2 context' do
		before { render(deep_contexts) }

		it 'sets parent to immediate parent name' do
			expect(read('site_tlc_io/io/input.md')).to be =~ /^parent: IO$/
		end

		it 'sets grand_parent to grandparent name' do
			expect(read('site_tlc_io/io/input.md')).to be =~ /^grand_parent: Site::Tlc::Io$/
		end
	end

	with 'page headings' do
		it 'uses full_name for root H1' do
			render(simple_contexts)
			expect(read('site_core.md')).to be =~ /^# Site::Core$/
		end

		it 'drops root component for child H1' do
			render(nested_contexts)
			expect(read('site_tlc_alarm/alarm.md')).to be =~ /^# Alarm$/
		end

		it 'drops root component for grandchild H1' do
			render(deep_contexts)
			expect(read('site_tlc_io/io/input.md')).to be =~ /^# IO Input$/
		end
	end

	with 'spec sections' do
		before { render(simple_contexts) }

		it 'renders spec heading' do
			expect(read('site_core.md')).to be =~ /^## Site::core connects$/
		end

		it 'renders spec docstring' do
			expect(read('site_core.md')).to be(:include?, 'Verify the site connects correctly')
		end

		it 'renders collapsible source block' do
			content = read('site_core.md')
			expect(content).to be(:include?, '<details markdown="block">')
			expect(content).to be(:include?, '```ruby')
			expect(content).to be(:include?, 'connects')
		end
	end

	with 'table-of-contents markers' do
		it 'includes spec TOC when specs are present' do
			render(simple_contexts)
			content = read('site_core.md')
			expect(content).to be(:include?, '### Tests')
			expect(content).to be(:include?, '- TOC')
		end

		it 'omits spec TOC when no specs' do
			render(nested_contexts)
			expect(read('site_tlc_alarm.md')).not.to be(:include?, '### Tests')
		end

		it 'includes context TOC when subcontexts exist' do
			render(nested_contexts)
			content = read('site_tlc_alarm.md')
			expect(content).to be(:include?, '### Categories')
			expect(content).to be(:include?, '[Alarm]')
			expect(content).to be(:include?, '[Alarm List]')
		end

		it 'uses Jekyll link syntax in context TOC' do
			render(nested_contexts)
			expect(read('site_tlc_alarm.md')).to be =~ /site\.baseurl.*link tests\/site_tlc_alarm\/alarm\.md/
		end

		it 'omits context TOC when no subcontexts' do
			render(simple_contexts)
			expect(read('site_core.md')).not.to be(:include?, '### Categories')
		end
	end

	with 'context docstring' do
		it 'renders the describe-block docstring' do
			render(edge_contexts)
			expect(read('site_core/connection_sequence.md')).to be(:include?, 'A context with its own docstring.')
		end
	end

	with 'file creation' do
		it 'creates all expected files for nested fixtures' do
			render(nested_contexts)
			expect(File.exist?(File.join(tmp, 'site_tlc_alarm.md'))).to be == true
			expect(File.exist?(File.join(tmp, 'site_tlc_alarm/alarm.md'))).to be == true
			expect(File.exist?(File.join(tmp, 'site_tlc_alarm/alarm_list.md'))).to be == true
		end

		it 'creates all expected files for deep fixtures' do
			render(deep_contexts)
			expect(File.exist?(File.join(tmp, 'site_tlc_io.md'))).to be == true
			expect(File.exist?(File.join(tmp, 'site_tlc_io/io.md'))).to be == true
			expect(File.exist?(File.join(tmp, 'site_tlc_io/io/input.md'))).to be == true
		end
	end
end
