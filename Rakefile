desc "Build documentation with YARD"
task :yard do
	system 'bundle exec yardoc spec/site -o docs/dev'
end

desc "Prepare Jekyll documentation branch."
task :docs do
	system 'git checkout gh-pages '

	# use --no-overlay to remove deleted files
	# see https://git-scm.com/docs/git-checkout#Documentation/git-checkout.txt---no-overlay
	system 'git checkout master --no-overlay -- docs'

	system 'git add .'

	# afterwards, you will usually commit changes and push to github
end
