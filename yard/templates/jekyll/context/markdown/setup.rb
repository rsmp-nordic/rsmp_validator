def init
	super
	sections :frontmatter, :content, :docstring
end

def get_parent_title obj
	if obj.parent.type.to_s == 'rspec'
		'Tests'
	else
		obj.parent.name
	end
end


def frontmatter
	frontmatter = {
		layout: 'page',
		title: object.name
	}
	frontmatter[:parent] = get_parent_title(object) if object.parent

	<<~HEREDOC
	---
	#{ frontmatter.map {|k,v| "#{k}: #{v}\n" }.join.strip }
	---

	HEREDOC
end

def content
	<<~HEREDOC
	# #{object.name}

	HEREDOC
end

#def subs
#  object.children.map do |child|
#  	"- #{child.name}"
#  end.join("\n") + "\n\n"
#end

def docstring
  object.docstring.strip + "\n\n"
end
