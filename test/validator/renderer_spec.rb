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

	with 'frontmatter — root context' do
		before { render(simple_contexts) }

		it 'sets parent to Test Suite' do
			expect(read('site.md')).to be =~ /^parent: Test Suite$/
		end

		it 'does not include grand_parent' do
			expect(read('site.md')).not.to be(:include?, 'grand_parent')
		end

		it 'sets has_children true when subcontexts exist' do
			expect(read('site.md')).to be =~ /^has_children: true$/
		end

		it 'sets layout to page' do
			expect(read('site.md')).to be =~ /^layout: page$/
		end

		it 'sets title to the humanized context name' do
			expect(read('site.md')).to be =~ /^title: Site$/
		end

		it 'sets has_toc to false' do
			expect(read('site.md')).to be =~ /^has_toc: false$/
		end
	end

	with 'frontmatter — depth-1 context' do
		before { render(simple_contexts) }

		it 'sets parent to humanized parent name' do
			expect(read('site/core.md')).to be =~ /^parent: Site$/
		end

		it 'sets grand_parent to Test Suite' do
			expect(read('site/core.md')).to be =~ /^grand_parent: Test Suite$/
		end

		it 'sets has_children false when no subcontexts' do
			expect(read('site/core.md')).to be =~ /^has_children: false$/
		end
	end

	with 'frontmatter — deeper namespace contexts' do
		before { render(nested_contexts) }

		it 'alarm namespace page has Tlc as parent' do
			expect(read('site/tlc/alarm.md')).to be =~ /^parent: Tlc$/
		end

		it 'alarm namespace page has Site as grand_parent' do
			expect(read('site/tlc/alarm.md')).to be =~ /^grand_parent: Site$/
		end

		it 'alarm literal page has Alarm as parent' do
			expect(read('site/tlc/alarm/alarm.md')).to be =~ /^parent: Alarm$/
		end

		it 'alarm literal page has Tlc as grand_parent' do
			expect(read('site/tlc/alarm/alarm.md')).to be =~ /^grand_parent: Tlc$/
		end

		it 'alarm_list sibling has same parent and grand_parent' do
			expect(read('site/tlc/alarm/alarm_list.md')).to be =~ /^parent: Alarm$/
			expect(read('site/tlc/alarm/alarm_list.md')).to be =~ /^grand_parent: Tlc$/
		end
	end

	with 'frontmatter — deeply nested context' do
		before { render(deep_contexts) }

		it 'sets parent to immediate parent name' do
			expect(read('site/tlc/io/io/input.md')).to be =~ /^parent: IO$/
		end

		it 'sets grand_parent to grandparent name' do
			expect(read('site/tlc/io/io/input.md')).to be =~ /^grand_parent: Io$/
		end
	end

	with 'page headings' do
		it 'uses humanized name for root H1' do
			render(simple_contexts)
			expect(read('site.md')).to be =~ /^# Site$/
		end

		it 'uses humanized name for depth-1 H1' do
			render(simple_contexts)
			expect(read('site/core.md')).to be =~ /^# Core$/
		end

		it 'uses humanized name for deeper H1' do
			render(nested_contexts)
			expect(read('site/tlc/alarm.md')).to be =~ /^# Alarm$/
		end

		it 'uses humanized name for deeply nested H1' do
			render(deep_contexts)
			expect(read('site/tlc/io/io/input.md')).to be =~ /^# Input$/
		end
	end

	with 'spec sections' do
		before { render(simple_contexts) }

		it 'renders spec heading with humanized parent name' do
			expect(read('site/core.md')).to be =~ /^## Core connects$/
		end

		it 'renders spec docstring' do
			expect(read('site/core.md')).to be(:include?, 'Verify the site connects correctly')
		end

		it 'renders collapsible source block' do
			content = read('site/core.md')
			expect(content).to be(:include?, '<details markdown="block">')
			expect(content).to be(:include?, '```ruby')
			expect(content).to be(:include?, 'connects')
		end
	end

	with 'table-of-contents markers' do
		it 'includes spec TOC when specs are present' do
			render(simple_contexts)
			content = read('site/core.md')
			expect(content).to be(:include?, '### Tests')
			expect(content).to be(:include?, '- TOC')
		end

		it 'omits spec TOC when no specs' do
			render(simple_contexts)
			expect(read('site.md')).not.to be(:include?, '### Tests')
		end

		it 'includes context TOC when subcontexts exist' do
			render(nested_contexts)
			content = read('site/tlc/alarm.md')
			expect(content).to be(:include?, '### Categories')
			expect(content).to be(:include?, '[Alarm]')
			expect(content).to be(:include?, '[Alarm List]')
		end

		it 'uses Jekyll link syntax in context TOC' do
			render(nested_contexts)
			expect(read('site/tlc/alarm.md')).to be =~ /site\.baseurl.*link tests\/site\/tlc\/alarm\/alarm\.md/
		end

		it 'omits context TOC when no subcontexts' do
			render(simple_contexts)
			expect(read('site/core.md')).not.to be(:include?, '### Categories')
		end
	end

	with 'context docstring' do
		it 'renders the describe-block docstring' do
			render(edge_contexts)
			expect(read('site/core/connection_sequence.md')).to be(:include?, 'A context with its own docstring.')
		end
	end

	with 'file creation' do
		it 'creates all expected files for nested fixtures' do
			render(nested_contexts)
			expect(File.exist?(File.join(tmp, 'site.md'))).to be == true
			expect(File.exist?(File.join(tmp, 'site/tlc.md'))).to be == true
			expect(File.exist?(File.join(tmp, 'site/tlc/alarm.md'))).to be == true
			expect(File.exist?(File.join(tmp, 'site/tlc/alarm/alarm.md'))).to be == true
			expect(File.exist?(File.join(tmp, 'site/tlc/alarm/alarm_list.md'))).to be == true
		end

		it 'creates all expected files for deep fixtures' do
			render(deep_contexts)
			expect(File.exist?(File.join(tmp, 'site.md'))).to be == true
			expect(File.exist?(File.join(tmp, 'site/tlc.md'))).to be == true
			expect(File.exist?(File.join(tmp, 'site/tlc/io.md'))).to be == true
			expect(File.exist?(File.join(tmp, 'site/tlc/io/io.md'))).to be == true
			expect(File.exist?(File.join(tmp, 'site/tlc/io/io/input.md'))).to be == true
		end
	end
end
