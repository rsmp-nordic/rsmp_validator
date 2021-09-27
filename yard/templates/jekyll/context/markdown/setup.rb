def init
	super
	sections :frontmatter, :content, :docstring
end

def get_parent_title obj
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
		section_id: object.path
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

def content
	<<~HEREDOC
	# #{object.full_name}
	
	HEREDOC
end

def docstring
  object.docstring.strip + "\n\n"
end
