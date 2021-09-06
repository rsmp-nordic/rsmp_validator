# Rake tasks for updating documentation.
# We use the branch gh-pages as the publishing source on GitHub Pages,
# and the Rake tasks commit to this branch.
#
# When updating gh-pages from master, we use --no-overlay to ensure that deleted files are removed, see:
# https://git-scm.com/docs/git-checkout#Documentation/git-checkout.txt---no-overlay

desc "\
Build documentation with YARD. \
Updates YARD docs based on relevant folders in spec/ and commits the result to the gh-pages branch.\
"
task :yard do
	system 'bundle exec yardoc'
	system 'git checkout gh-pages'
	system 'git add .'
	system 'git status'
	system 'git commit -m "update yard docs"'
end

desc "\
Prepare Jekyll documentation branch. 
Merges docs/ from the master branch to the gh-pages branch.\
\
"
task :docs do
	system 'git checkout gh-pages'
	system 'git checkout master --no-overlay -- docs'
	system 'git add .'
	system 'git status'
	system 'git commit -m "update jekyll docs"'
end
