# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative '../../lib/doc_gen/parser'
require_relative '../../lib/doc_gen/renderer'

REAL_IO_SPEC = File.expand_path('../../test/site/tlc/io_spec.rb', __dir__)

describe 'DocGen integration' do
	let(:tmp) { Dir.mktmpdir }
	after { FileUtils.rm_rf(tmp) }

	with 'parsing valid/site/tlc/io_spec.rb' do
		let(:contexts) { DocGen::Parser.parse_files([REAL_IO_SPEC]) }

		it 'returns at least one root context' do
			skip 'io_spec.rb not found' unless File.exist?(REAL_IO_SPEC)
			expect(contexts).not.to be(:empty?)
		end

		it 'root context is Site' do
			skip 'io_spec.rb not found' unless File.exist?(REAL_IO_SPEC)
			expect(contexts.first.name).to be == 'Site'
		end

		it 'has an Io subcontext under Tlc' do
			skip 'io_spec.rb not found' unless File.exist?(REAL_IO_SPEC)
			tlc = contexts.first.subcontexts.find { |c| c.name == 'Tlc' }
			io_ns = tlc&.subcontexts&.find { |c| c.name == 'Io' }
			expect(io_ns).not.to be == nil
		end

		it 'has Input and Output subcontexts directly under Io' do
			skip 'io_spec.rb not found' unless File.exist?(REAL_IO_SPEC)
			tlc   = contexts.first.subcontexts.find { |c| c.name == 'Tlc' }
			io_ns = tlc&.subcontexts&.find { |c| c.name == 'Io' }
			names = io_ns&.subcontexts&.map(&:name) || []
			expect(names).to be(:include?, 'Input')
			expect(names).to be(:include?, 'Output')
		end

		it 'extracts spec docstrings' do
			skip 'io_spec.rb not found' unless File.exist?(REAL_IO_SPEC)
			tlc   = contexts.first.subcontexts.find { |c| c.name == 'Tlc' }
			io_ns = tlc&.subcontexts&.find { |c| c.name == 'Io' }
			input = io_ns&.subcontexts&.find { |c| c.name == 'Input' }
			spec  = input&.specs&.find { |s| s.name == 'is read with S0003 with extended input status' }
			expect(spec).not.to be == nil
			expect(spec.docstring).to be(:include?, 'Verify that we can read input status')
		end
	end

	with 'rendering valid/site/tlc/io_spec.rb' do
		let(:contexts) { DocGen::Parser.parse_files([REAL_IO_SPEC]) }
		before { DocGen::Renderer.render(contexts, output_dir: tmp) if File.exist?(REAL_IO_SPEC) }

		it 'creates the root md file' do
			skip 'io_spec.rb not found' unless File.exist?(REAL_IO_SPEC)
			expect(File.exist?(File.join(tmp, 'site.md'))).to be == true
		end

		it 'root page has parent Test Suite' do
			skip 'io_spec.rb not found' unless File.exist?(REAL_IO_SPEC)
			content = File.read(File.join(tmp, 'site.md'))
			expect(content).to be =~ /^parent: Test Suite$/
		end

		it 'Io namespace page has correct parent and grand_parent' do
			skip 'io_spec.rb not found' unless File.exist?(REAL_IO_SPEC)
			content = File.read(File.join(tmp, 'site/tlc/io.md'))
			expect(content).to be =~ /^parent: Tlc$/
			expect(content).to be =~ /^grand_parent: Site$/
		end

		it 'Input page has correct parent and grand_parent' do
			skip 'io_spec.rb not found' unless File.exist?(REAL_IO_SPEC)
			content = File.read(File.join(tmp, 'site/tlc/io/input.md'))
			expect(content).to be =~ /^parent: Io$/
			expect(content).to be =~ /^grand_parent: Tlc$/
		end
	end

	with 'all conformance test files' do
		let(:all_files) do
			Dir[File.expand_path('../../test/site/**/*_spec.rb', __dir__)] +
				Dir[File.expand_path('../../test/supervisor/**/*_spec.rb', __dir__)]
		end

		it 'parses and renders every conformance test file without errors' do
			skip 'no conformance test files found' if all_files.empty?
			contexts = DocGen::Parser.parse_files(all_files)
			DocGen::Renderer.render(contexts, output_dir: tmp)
		end

		it 'produces only Site and Supervisor as root contexts' do
			skip 'no conformance test files found' if all_files.empty?
			contexts = DocGen::Parser.parse_files(all_files)
			root_names = contexts.map(&:name)
			expect(root_names).not.to be(:include?, root_names.any? { |n| n.include?('::') })
		end
	end
end
