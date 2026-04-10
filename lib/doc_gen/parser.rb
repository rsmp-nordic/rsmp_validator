# frozen_string_literal: true

require 'prism'

# DocGen: Prism-based parser and Jekyll Markdown renderer for test documentation.
# Replaces the YARD-based documentation pipeline.
#
# Usage:
#   require_relative 'lib/doc_gen/parser'
#   require_relative 'lib/doc_gen/renderer'
#
#   contexts = DocGen::Parser.parse_files(Dir['test/**/*_spec.rb'])
#   DocGen::Renderer.render(contexts, output_dir: 'docs/tests')

module DocGen
  # A context represents a `describe` block. It holds child contexts and specs.
  Context = Struct.new(:name, :docstring, :children, :file, :line, :parent, keyword_init: true) do
    # Direct child specs (it/specify blocks).
    def specs
      children.select { |c| c.is_a?(Spec) }
    end

    # Direct child contexts (nested describe blocks).
    def subcontexts
      children.select { |c| c.is_a?(Context) }
    end

    # Full display name, dropping the root component when nested (matches YARD behaviour).
    # Examples:
    #   root 'Site::Tlc::Io'       => 'Site::Tlc::Io'
    #   child 'IO' of above         => 'IO'
    #   grandchild 'Input' of above => 'IO Input'
    def full_name
      parts = [name]
      ctx = parent
      while ctx.is_a?(Context)
        parts.unshift(ctx.name)
        ctx = ctx.parent
      end
      parts.shift if parts.size > 1
      parts.join(' ')
    end

    # Hierarchical output path relative to the output directory root.
    # Examples:
    #   root 'Site::Tlc::Io'              => 'site_tlc_io.md'
    #   child 'IO'                         => 'site_tlc_io/io.md'
    #   grandchild 'Input'                 => 'site_tlc_io/io/input.md'
    def output_path
      parts = []
      ctx = self
      while ctx.is_a?(Context)
        parts.unshift(DocGen.slugify(ctx.name))
        ctx = ctx.parent
      end
      parts.join('/') + '.md'
    end
  end

  # A spec represents an `it` or `specify` block.
  Spec = Struct.new(:name, :docstring, :source, :file, :line, :parent, keyword_init: true) do
    # Full display name including ancestors (root component dropped, same as Context).
    def full_name
      parts = [name]
      ctx = parent
      while ctx.is_a?(Context)
        parts.unshift(ctx.name)
        ctx = ctx.parent
      end
      parts.shift if parts.size > 1
      parts.join(' ')
    end
  end

  # Convert a name to a URL/filesystem-friendly slug.
  def self.slugify(name)
    name.gsub('::', '_')
        .gsub(/[^a-zA-Z0-9_]+/, '_')
        .gsub(/_+/, '_')
        .gsub(/\A_+|_+\z/, '')
        .downcase
  end

  # Convert a raw describe name to a human-readable title.
  # Takes the last :: segment and splits CamelCase into words.
  # Examples:
  #   'Site::Tlc::DetectorLogics' => 'Detector Logics'
  #   'Site::Core'                => 'Core'
  #   'Detector Logic'            => 'Detector Logic'  (already readable)
  def self.humanize(name)
    segment = name.split('::').last || name
    segment.gsub(/([a-z\d])([A-Z])/, '\1 \2')
           .gsub(/([A-Z]+)([A-Z][a-z])/, '\1 \2')
  end

  # Parses Ruby test files using Prism and builds a tree of Context and Spec objects.
  class Parser
    # Parse an array of file paths and return an array of root Context objects.
    def self.parse_files(paths)
      new.parse_files(paths)
    end

    def parse_files(paths)
      raw = Array(paths).flat_map { |path| parse_file(path) }
      build_namespace_tree(raw)
    end

    private

    # Merge raw contexts into a tree by splitting their names on '::'.
    # e.g. 'Site::Tlc::Alarm' becomes Site -> Tlc -> Alarm in the tree.
    # Stub contexts (plain 'Site' or 'Supervisor' with empty inner describes) have
    # their docstrings merged into the tree and empty children dropped.
    def build_namespace_tree(raw_contexts)
      node_map = {}  # 'Site::Tlc' => Context node

      # Process namespaced contexts first so intermediate nodes exist when stubs run
      sorted = raw_contexts.sort_by { |ctx| ctx.name.include?('::') ? 0 : 1 }

      sorted.each do |raw|
        segments = raw.name.split('::')

        # Create or find each prefix node
        segments.each_with_index do |seg, i|
          path = segments[0..i].join('::')
          next if node_map.key?(path)

          parent_path = i > 0 ? segments[0...i].join('::') : nil
          parent_node = parent_path ? node_map[parent_path] : nil

          node = Context.new(
            name: seg,
            docstring: nil,
            children: [],
            file: raw.file,
            line: raw.line,
            parent: parent_node
          )
          node_map[path] = node
          parent_node.children << node if parent_node
        end

        # Fill leaf node
        leaf = node_map[raw.name]
        leaf.docstring ||= raw.docstring

        # Adopt children, merging namespace-matched children and dropping empty stubs
        raw.children.each do |child|
          if child.is_a?(Context)
            existing = leaf.children.find { |c| c.is_a?(Context) && c.name == child.name }
            if existing
              # Merge docstring and adopt grandchildren for non-empty stubs
              existing.docstring ||= child.docstring
              child.children.each do |grandchild|
                grandchild.parent = existing
                existing.children << grandchild
              end
            elsif child.children.any?
              # Non-empty literal child: add as-is
              child.parent = leaf
              leaf.children << child
            end
            # Empty unmatched literal child (YARD stub): silently drop
          else
            child.parent = leaf
            leaf.children << child
          end
        end
      end

      node_map.values.select { |n| n.parent.nil? }
    end

    def parse_file(path)
      source = File.read(path)
      result = Prism.parse(source)
      lines = source.lines
      comment_map = build_comment_map(result, lines)
      top_nodes = result.value.statements&.body || []
      parse_block(top_nodes, path, comment_map, lines, nil)
    end

    # Recursively parses a list of AST nodes, building Context/Spec objects.
    # Returns root-level contexts when parent_context is nil; otherwise mutates parent.
    def parse_block(nodes, file, comment_map, lines, parent_context)
      roots = []
      Array(nodes).each do |node|
        next unless node.is_a?(Prism::CallNode)

        case node.name
        when :describe
          name = string_arg(node)
          next unless name

          docstring = extract_docstring(node.location.start_line, comment_map)
          ctx = Context.new(
            name: name,
            docstring: docstring,
            children: [],
            file: file,
            line: node.location.start_line,
            parent: parent_context
          )
          parent_context ? parent_context.children << ctx : roots << ctx
          if (body = block_body(node))
            parse_block(body, file, comment_map, lines, ctx)
          end

        when :it, :specify
          name = string_arg(node)
          next unless name
          next unless parent_context.is_a?(Context)

          docstring = extract_docstring(node.location.start_line, comment_map)
          source = extract_source(node, lines)
          spec = Spec.new(
            name: name,
            docstring: docstring,
            source: source,
            file: file,
            line: node.location.start_line,
            parent: parent_context
          )
          parent_context.children << spec
        end
      end
      roots
    end

    # Build a map of line_number => comment_text for standalone comment lines only.
    # Inline comments (e.g. `foo # bar`) are excluded.
    def build_comment_map(result, lines)
      result.comments.each_with_object({}) do |comment, map|
        line_num = comment.location.start_line
        source_line = lines[line_num - 1] || ''
        map[line_num] = comment.slice if source_line.strip.start_with?('#')
      end
    end

    # Extract the string value of the first argument to a call node.
    # Returns nil for non-string or missing arguments.
    def string_arg(node)
      return nil unless node.arguments

      first = node.arguments.arguments.first
      case first
      when Prism::StringNode then first.unescaped
      when Prism::SymbolNode then first.unescaped
      else nil
      end
    end

    # Return the body statement array from a block node, or nil.
    def block_body(node)
      return nil unless node.block&.body

      body = node.block.body
      body.is_a?(Prism::StatementsNode) ? body.body : nil
    end

    # Walk backwards from the line before start_line collecting contiguous comment lines.
    # A blank line or non-comment line stops the collection.
    def extract_docstring(start_line, comment_map)
      doc_lines = []
      current = start_line - 1
      while comment_map[current]
        doc_lines.unshift(comment_map[current].sub(/^\s*#\s?/, ''))
        current -= 1
      end
      doc_lines.join("\n").strip
    end

    # Extract the full source of the `it`/`specify` call (including block body).
    def extract_source(node, lines)
      start = node.location.start_line - 1
      stop  = node.location.end_line
      lines[start...stop].join.chomp
    end
  end
end
