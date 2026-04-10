# frozen_string_literal: true

require 'fileutils'
require_relative 'parser'

module DocGen
  # Renders a tree of Context objects to Jekyll-compatible Markdown files.
  # Output matches the format previously produced by the YARD jekyll template.
  #
  # Frontmatter fields produced:
  #   layout, title, parmalink (sic — preserved from original for compatibility),
  #   has_children, has_toc, parent, grand_parent (when applicable)
  #
  # Jekyll nav hierarchy (just-the-docs):
  #   depth 0  ->  parent: "Test Suite"  (no grand_parent)
  #   depth 1  ->  parent: <root name>,  grand_parent: "Test Suite"
  #   depth 2+ ->  parent: <direct parent name>,  grand_parent: <grandparent name or "Test Suite">
  class Renderer
    # Render an array of root Context objects to output_dir.
    def self.render(contexts, output_dir:)
      new(output_dir: output_dir).render(contexts)
    end

    def initialize(output_dir:)
      @output_dir = output_dir
    end

    def render(contexts)
      FileUtils.mkdir_p(@output_dir)
      contexts.each { |ctx| render_context(ctx) }
    end

    private

    # Write a single context page and recurse into subcontexts.
    def render_context(ctx)
      path = File.join(@output_dir, ctx.output_path)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, context_content(ctx))
      ctx.subcontexts.each { |child| render_context(child) }
    end

    # Assemble the full Markdown content for a context page.
    def context_content(ctx)
      parts = [
        frontmatter(ctx),
        page_title(ctx),
        description(ctx)
      ]
      parts << context_toc(ctx)   if ctx.subcontexts.any?
      parts << specification_toc  if ctx.specs.any?
      parts << specifications(ctx) if ctx.specs.any?
      parts.join
    end

    # Jekyll frontmatter block.
    def frontmatter(ctx)
      fields = {
        layout:       'page',
        title:        DocGen.humanize(ctx.name),
        parmalink:    DocGen.slugify(ctx.full_name),
        has_children: ctx.subcontexts.any?,
        has_toc:      false,
        parent:       parent_title(ctx)
      }
      grand = grand_parent_title(ctx)
      fields[:grand_parent] = grand if grand

      lines = fields.map { |k, v| "#{k}: #{v}" }.join("\n")
      "---\n#{lines}\n---\n\n"
    end

    # H1 heading using humanized name.
    def page_title(ctx)
      "# #{DocGen.humanize(ctx.name)}\n{: .no_toc}\n\n"
    end

    # Context-level docstring (comment above the describe block), if present.
    def description(ctx)
      return '' if ctx.docstring.nil? || ctx.docstring.strip.empty?

      "#{ctx.docstring.strip}\n\n"
    end

    # Sorted list of links to child contexts.
    def context_toc(ctx)
      items = ctx.subcontexts.sort_by(&:name).map do |child|
        "- [#{DocGen.humanize(child.name)}]({{ site.baseurl }}{% link #{link_path(child)} %})"
      end.join("\n")

      "### Categories\n{: .no_toc .text-delta }\n#{items}\n\n"
    end

    # just-the-docs inline TOC marker (picks up ## headings from spec sections).
    def specification_toc
      "### Tests\n{: .no_toc .text-delta }\n\n- TOC\n{:toc}\n\n"
    end

    # All spec sections for the context, sorted by name.
    def specifications(ctx)
      ctx.specs.sort_by(&:name).map { |spec| spec_section(spec) }.join("\n\n")
    end

    # One spec rendered as a ## section with docstring and collapsible source.
    def spec_section(spec)
      heading   = "## #{DocGen.humanize(spec.parent.name)} #{spec.name}"
      docstring = spec.docstring.to_s.strip
      src       = indent(spec.source.to_s)

      parts = [heading]
      parts << "\n\n#{docstring}" unless docstring.empty?
      parts << "\n\n<details markdown=\"block\">\n" \
               "  <summary>\n" \
               "     View Source\n" \
               "  </summary>\n" \
               "```ruby\n#{src}\n```\n" \
               "</details>"
      parts.join + "\n"
    end

    # De-indent source by the leading whitespace of the last line (YARD convention).
    def indent(source)
      lines = source.lines
      return source if lines.empty?

      n = /^(\s*)/.match(lines.last)[0].size
      lines.map do |line|
        i = [n, /^(\s*)/.match(line)[0].size].min
        line[i..]
      end.join
    end

    # Jekyll {% link %} path for a context (relative to the Jekyll site root).
    # Matches the `tests/` output prefix used by the rake task.
    def link_path(ctx)
      "tests/#{ctx.output_path}"
    end

    # Title of the logical parent for Jekyll frontmatter.
    # Returns "Test Suite" for root contexts (depth 0).
    def parent_title(ctx)
      ctx.parent ? DocGen.humanize(ctx.parent.name) : 'Test Suite'
    end

    # Title of the logical grandparent for Jekyll frontmatter.
    # Added for all non-root contexts (depth >= 1), matching YARD behaviour.
    # Returns nil for root contexts.
    def grand_parent_title(ctx)
      return nil unless ctx.parent

      parent_title(ctx.parent)
    end
  end
end
