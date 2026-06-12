# frozen_string_literal: true

require_relative '../../lib/doc_gen/parser'

FIXTURES_PATH = File.expand_path('../../fixtures/doc_gen', __dir__)

describe DocGen::Parser do
  with 'simple.rb - flat describe with specs' do
    let(:contexts) { DocGen::Parser.parse_files(["#{FIXTURES_PATH}/simple.rb"]) }
    let(:site) { contexts.first }
    let(:core) { site.subcontexts.first }

    it 'returns one root context' do
      expect(contexts.size).to be == 1
    end

    it 'root has name Site' do
      expect(site.name).to be == 'Site'
    end

    it 'root has no parent' do
      expect(site.parent).to be_nil
    end

    it 'root has one subcontext (Core)' do
      expect(site.subcontexts.size).to be == 1
    end

    it 'Core has three specs' do
      expect(core.specs.size).to be == 3
    end

    it 'has the expected spec names' do
      names = core.specs.map(&:name)
      expect(names).to be(:include?, 'connects')
      expect(names).to be(:include?, 'disconnects')
      expect(names).to be(:include?, 'has no docstring')
    end

    it 'extracts a multi-line docstring' do
      connects = core.specs.find { |s| s.name == 'connects' }
      expect(connects.docstring).to be(:include?, 'Verify the site connects correctly.')
      expect(connects.docstring).to be(:include?, '1. Given the site is connected')
    end

    it 'returns empty docstring when no comment precedes the spec' do
      no_doc = core.specs.find { |s| s.name == 'has no docstring' }
      expect(no_doc.docstring).to be == ''
    end

    it 'extracts a single-line docstring' do
      disconnects = core.specs.find { |s| s.name == 'disconnects' }
      expect(disconnects.docstring).to be(:include?, 'Verify the site disconnects.')
    end

    it 'captures spec source containing the it keyword' do
      connects = core.specs.find { |s| s.name == 'connects' }
      expect(connects.source).to be =~ /\bit\b/
      expect(connects.source).to be(:include?, 'connects')
    end

    it 'sets the spec parent to the Core context' do
      connects = core.specs.find { |s| s.name == 'connects' }
      expect(connects.parent.object_id).to be == core.object_id
    end

    it 'records the file and line' do
      expect(site.file).to be == "#{FIXTURES_PATH}/simple.rb"
      expect(site.line).to be(:positive?)
    end
  end

  with 'nested.rb - two-level nesting' do
    let(:site) { DocGen::Parser.parse_files(["#{FIXTURES_PATH}/nested.rb"]).first }
    let(:tlc)  { site.subcontexts.first }
    let(:ctx)  { tlc.subcontexts.first } # Alarm namespace node

    it 'has two subcontexts under Alarm' do
      expect(ctx.subcontexts.size).to be == 2
    end

    it 'Alarm namespace has no direct specs' do
      expect(ctx.specs.size).to be(:zero?)
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

    it 'child context parent points to Alarm namespace' do
      alarm = ctx.subcontexts.find { |c| c.name == 'Alarm' }
      expect(alarm.parent.object_id).to be == ctx.object_id
    end

    it 'extracts child spec docstring' do
      alarm = ctx.subcontexts.find { |c| c.name == 'Alarm' }
      raised = alarm.specs.find { |s| s.name == 'is raised' }
      expect(raised.docstring).to be(:include?, 'Verify that an alarm is raised.')
    end
  end

  with 'deep.rb - namespace tree plus nested describes' do
    let(:contexts) { DocGen::Parser.parse_files(["#{FIXTURES_PATH}/deep.rb"]) }
    let(:site)   { contexts.first }
    let(:tlc)    { site.subcontexts.first }
    let(:io_ns)  { tlc.subcontexts.first } # Io namespace node
    let(:io)     { io_ns.subcontexts.first }  # IO literal describe
    let(:input)  { io.subcontexts.first }     # Input literal describe

    it 'parses all levels' do
      expect(site.name).to be == 'Site'
      expect(tlc.name).to be == 'Tlc'
      expect(io_ns.name).to be == 'Io'
      expect(io.name).to be == 'IO'
      expect(input.name).to be == 'Input'
      expect(input.specs.first.name).to be == 'is read with S0003'
    end

    it 'builds the correct parent chain' do
      expect(io.parent.object_id).to be == io_ns.object_id
      expect(input.parent.object_id).to be == io.object_id
      expect(site.parent).to be_nil
    end
  end

  with 'full_name' do
    it 'returns the name for a root context' do
      site = DocGen::Parser.parse_files(["#{FIXTURES_PATH}/simple.rb"]).first
      expect(site.full_name).to be == 'Site'
    end

    it 'returns just the name for a direct child (root dropped)' do
      site = DocGen::Parser.parse_files(["#{FIXTURES_PATH}/simple.rb"]).first
      core = site.subcontexts.first
      expect(core.full_name).to be == 'Core'
    end

    it 'joins grandparent and child names (root dropped)' do
      site = DocGen::Parser.parse_files(["#{FIXTURES_PATH}/nested.rb"]).first
      tlc   = site.subcontexts.first
      alarm = tlc.subcontexts.first
      expect(alarm.full_name).to be == 'Tlc Alarm'
    end

    it 'joins all ancestor names for deep context (root dropped)' do
      site    = DocGen::Parser.parse_files(["#{FIXTURES_PATH}/deep.rb"]).first
      io_ns   = site.subcontexts.first.subcontexts.first
      io_lit  = io_ns.subcontexts.first
      input   = io_lit.subcontexts.first
      expect(input.full_name).to be == 'Tlc Io IO Input'
    end
  end

  with 'output_path' do
    it 'slugifies the root name' do
      site = DocGen::Parser.parse_files(["#{FIXTURES_PATH}/simple.rb"]).first
      expect(site.output_path).to be == 'site.md'
    end

    it 'nests child path under root slug' do
      site = DocGen::Parser.parse_files(["#{FIXTURES_PATH}/simple.rb"]).first
      core = site.subcontexts.first
      expect(core.output_path).to be == 'site/core.md'
    end

    it 'nests namespace and literal levels' do
      site = DocGen::Parser.parse_files(["#{FIXTURES_PATH}/nested.rb"]).first
      alarm = site.subcontexts.first.subcontexts.first
      expect(alarm.output_path).to be == 'site/tlc/alarm.md'
    end

    it 'nests deeply for literal describes inside namespace' do
      site = DocGen::Parser.parse_files(["#{FIXTURES_PATH}/deep.rb"]).first
      input = site.subcontexts.first.subcontexts.first.subcontexts.first.subcontexts.first
      expect(input.output_path).to be == 'site/tlc/io/io/input.md'
    end
  end

  with 'edge_cases.rb' do
    let(:contexts) { DocGen::Parser.parse_files(["#{FIXTURES_PATH}/edge_cases.rb"]) }

    it 'parses specify as an alias for it' do
      conn_seq = contexts.first.subcontexts.first.subcontexts.first
      expect(conn_seq.specs.size).to be == 1
      expect(conn_seq.specs.first.name).to be == 'uses specify alias'
    end

    it 'extracts a docstring from a describe block' do
      conn_seq = contexts.first.subcontexts.first.subcontexts.first
      expect(conn_seq.docstring).to be == 'A context with its own docstring.'
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
