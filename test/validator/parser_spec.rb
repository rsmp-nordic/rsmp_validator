# frozen_string_literal: true

require_relative '../../lib/doc_gen/parser'

FIXTURES_PATH = File.expand_path('../../fixtures/doc_gen', __dir__)

describe DocGen::Parser do
	with 'simple.rb — flat describe with specs' do
		let(:contexts) { DocGen::Parser.parse_files(["#{FIXTURES_PATH}/simple.rb"]) }
		let(:ctx) { contexts.first }

		it 'returns one root context' do
			expect(contexts.size).to be == 1
		end

		it 'has the correct name' do
			expect(ctx.name).to be == 'Site::Core'
		end

		it 'has no parent' do
			expect(ctx.parent).to be == nil
		end

		it 'has three specs' do
			expect(ctx.specs.size).to be == 3
		end

		it 'has the expected spec names' do
			names = ctx.specs.map(&:name)
			expect(names).to be(:include?, 'connects')
			expect(names).to be(:include?, 'disconnects')
			expect(names).to be(:include?, 'has no docstring')
		end

		it 'extracts a multi-line docstring' do
			connects = ctx.specs.find { |s| s.name == 'connects' }
			expect(connects.docstring).to be(:include?, 'Verify the site connects correctly.')
			expect(connects.docstring).to be(:include?, '1. Given the site is connected')
		end

		it 'returns empty docstring when no comment precedes the spec' do
			no_doc = ctx.specs.find { |s| s.name == 'has no docstring' }
			expect(no_doc.docstring).to be == ''
		end

		it 'extracts a single-line docstring' do
			disconnects = ctx.specs.find { |s| s.name == 'disconnects' }
			expect(disconnects.docstring).to be(:include?, 'Verify the site disconnects.')
		end

		it 'captures spec source containing the it keyword' do
			connects = ctx.specs.find { |s| s.name == 'connects' }
			expect(connects.source).to be =~ /\bit\b/
			expect(connects.source).to be(:include?, 'connects')
		end

		it 'sets the spec parent to the enclosing context' do
			connects = ctx.specs.find { |s| s.name == 'connects' }
			expect(connects.parent.object_id).to be == ctx.object_id
		end

		it 'records the file and line' do
			expect(ctx.file).to be == "#{FIXTURES_PATH}/simple.rb"
			expect(ctx.line).to be > 0
		end
	end

	with 'nested.rb — two-level nesting' do
		let(:ctx) { DocGen::Parser.parse_files(["#{FIXTURES_PATH}/nested.rb"]).first }

		it 'has two subcontexts' do
			expect(ctx.subcontexts.size).to be == 2
		end

		it 'has no direct specs' do
			expect(ctx.specs.size).to be == 0
		end

		it 'has the expected subcontext names' do
			names = ctx.subcontexts.map(&:name)
			expect(names).to be(:include?, 'Alarm')
			expect(names).to be(:include?, 'Alarm List')
		end

		it 'child context has two specs' do
			alarm = ctx.subcontexts.find { |c| c.name == 'Alarm' }
			expect(alarm.specs.size).to be == 2
		end

		it 'child context parent points to root' do
			alarm = ctx.subcontexts.find { |c| c.name == 'Alarm' }
			expect(alarm.parent.object_id).to be == ctx.object_id
		end

		it 'extracts child spec docstring' do
			alarm = ctx.subcontexts.find { |c| c.name == 'Alarm' }
			raised = alarm.specs.find { |s| s.name == 'is raised' }
			expect(raised.docstring).to be(:include?, 'Verify that an alarm is raised.')
		end
	end

	with 'deep.rb — three-level nesting' do
		let(:contexts) { DocGen::Parser.parse_files(["#{FIXTURES_PATH}/deep.rb"]) }
		let(:root)  { contexts.first }
		let(:io)    { root.subcontexts.first }
		let(:input) { io.subcontexts.first }

		it 'parses all three levels' do
			expect(root.name).to be == 'Site::Tlc::Io'
			expect(io.name).to be == 'IO'
			expect(input.name).to be == 'Input'
			expect(input.specs.first.name).to be == 'is read with S0003'
		end

		it 'builds the correct parent chain' do
			expect(io.parent.object_id).to be == root.object_id
			expect(input.parent.object_id).to be == io.object_id
			expect(root.parent).to be == nil
		end
	end

	with 'full_name' do
		it 'returns the context name for a root context' do
			ctx = DocGen::Parser.parse_files(["#{FIXTURES_PATH}/simple.rb"]).first
			expect(ctx.full_name).to be == 'Site::Core'
		end

		it 'drops the root component for a child context' do
			ctx = DocGen::Parser.parse_files(["#{FIXTURES_PATH}/nested.rb"]).first
			alarm = ctx.subcontexts.find { |c| c.name == 'Alarm' }
			expect(alarm.full_name).to be == 'Alarm'
		end

		it 'joins parent and child names for a grandchild' do
			input = DocGen::Parser.parse_files(["#{FIXTURES_PATH}/deep.rb"])
				.first.subcontexts.first.subcontexts.first
			expect(input.full_name).to be == 'IO Input'
		end
	end

	with 'output_path' do
		it 'slugifies the root name' do
			ctx = DocGen::Parser.parse_files(["#{FIXTURES_PATH}/simple.rb"]).first
			expect(ctx.output_path).to be == 'site_core.md'
		end

		it 'nests child path under root slug' do
			ctx = DocGen::Parser.parse_files(["#{FIXTURES_PATH}/nested.rb"]).first
			alarm = ctx.subcontexts.find { |c| c.name == 'Alarm' }
			expect(alarm.output_path).to be == 'site_tlc_alarm/alarm.md'
		end

		it 'nests grandchild path two levels deep' do
			input = DocGen::Parser.parse_files(["#{FIXTURES_PATH}/deep.rb"])
				.first.subcontexts.first.subcontexts.first
			expect(input.output_path).to be == 'site_tlc_io/io/input.md'
		end
	end

	with 'edge_cases.rb' do
		let(:contexts) { DocGen::Parser.parse_files(["#{FIXTURES_PATH}/edge_cases.rb"]) }

		it 'parses specify as an alias for it' do
			conn = contexts.first.subcontexts.first
			expect(conn.specs.size).to be == 1
			expect(conn.specs.first.name).to be == 'uses specify alias'
		end

		it 'extracts a docstring from a describe block' do
			conn = contexts.first.subcontexts.first
			expect(conn.docstring).to be == 'A context with its own docstring.'
		end
	end

	with 'DocGen.slugify' do
		it 'converts double colons to underscores' do
			expect(DocGen.slugify('Site::Core')).to be == 'site_core'
		end

		it 'converts spaces to underscores' do
			expect(DocGen.slugify('IO Input')).to be == 'io_input'
		end

		it 'lowercases the result' do
			expect(DocGen.slugify('Alarm List')).to be == 'alarm_list'
		end
	end
end
