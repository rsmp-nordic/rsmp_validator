include YARD::Templates::Helpers::HtmlHelper

def init
	super
	sections :frontmatter, :title, :docstring, :source
end

def get_parent_title object
	if object.parent.type.to_s == 'rspec'
		'Test Suite'
	else
		object.parent.name
	end
end

def frontmatter
	frontmatter = {
		layout: 'page',
		title: object.name
	}
	if object.parent
		frontmatter[:parent] = get_parent_title object
		frontmatter[:in_section] = object.parent.path
	end

	<<~HEREDOC
	---
	#{ frontmatter.map {|k,v| "#{k}: #{v}\n" }.join.strip }
	---

	HEREDOC
end

def title
	"# #{object.full_name}\n\n"
end

def docstring
  object.docstring.strip + "\n\n"
end

def indent source
	lines = source.lines
	n = /^(\s*)/.match(lines.last)[0].size
	lines.map do |line|
		i = [n, /^(\s*)/.match(line)[0].size].min
		line[i..-1]
	end.join
end

def source
	<<~HEREDOC
	```ruby
	#{indent object.source}
	```

	HEREDOC
end