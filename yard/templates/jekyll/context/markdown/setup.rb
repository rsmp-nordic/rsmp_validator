def init
  super
  sections :frontmatter, :title, :description, :context_toc, :specification_toc, :specifications
  @contexts = object.children.select { |child| child.type == :context }
  @specifications = object.children.select { |child| child.type == :specification }
end

def get_parent_title(obj)
  if obj.parent.type.to_s == 'rspec'
    'Test Suite'
  else
    obj.parent.name
  end
end

def frontmatter
  frontmatter = {
    layout: 'page',
    title: object.name,
    parmalink: object_permalink(object),
    has_children: @contexts.any?,
    has_toc: false
  }

  if object.parent
    frontmatter[:parent] = get_parent_title object
    frontmatter[:grand_parent] = get_parent_title object.parent unless object.parent.parent.root?
  end

  <<~HEREDOC
    ---
    #{frontmatter.map { |k, v| "#{k}: #{v}\n" }.join.strip}
    ---

  HEREDOC
end

def title
  <<~HEREDOC
    # #{object.full_name}
    {: .no_toc}

  HEREDOC
end

def description
  object.docstring.strip + "\n\n"
end

def object_permalink(obj)
  obj.full_name.gsub(' ', '_').downcase
end

def object_link(obj)
  'tests/' + options.serializer.serialized_path(obj).gsub('.html', '.md')
end

def context_toc
  toc = @contexts.sort_by(&:name).map do |context|
    "- [#{context.name}]({{ site.baseurl }}{% link #{object_link context} %})"
  end.join("\n")

  return unless @contexts.any?

  <<~HEREDOC
    ### Categories
    {: .no_toc .text-delta }
    #{toc}

  HEREDOC
end

def specification_toc
  return unless @specifications.any?

  <<~HEREDOC
    ### Tests
    {: .no_toc .text-delta }

    - TOC
    {:toc}

  HEREDOC
end

def specifications
  @specifications.sort_by(&:name).map do |spec|
    specification spec
  end.join("\n\n")
end

def indent(source)
  lines = source.lines
  n = /^(\s*)/.match(lines.last)[0].size
  lines.map do |line|
    i = [n, /^(\s*)/.match(line)[0].size].min
    line[i..-1]
  end.join
end

def specification(spec)
  <<~HEREDOC
    ## #{spec.parent.name.capitalize} #{spec.name}

    #{spec.docstring.strip}

    <details markdown="block">
      <summary>
         View Source
      </summary>
    ```ruby
    #{indent spec.source}
    ```
    </details>


  HEREDOC
end
