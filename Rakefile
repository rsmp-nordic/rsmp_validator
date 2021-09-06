desc "Build documentation with YARD"
task :yard do
	system 'bundle exec yardoc spec/site -o docs/dev'
end

desc "Prepare Jekyll documentation branch."
task :docs do
	# pull changes from master into gh-pages and commit
	# use --no-overlay to ensure that deleted files are removed
	# see https://git-scm.com/docs/git-checkout#Documentation/git-checkout.txt---no-overlay
	system 'git checkout gh-pages'
	system 'git checkout master --no-overlay -- docs'
	system 'git add .'
	system 'git commit -m "update docs"'
end
