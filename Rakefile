desc "Build documentation with YARD"
task :yard do
	system 'bundle exec yardoc spec/site -o docs/dev'
end

desc "Build documentation with YARD"
task :docs do
	system 'git checkout gh-pages'
	system 'git checkout master -- docs'
	system 'git add .'
end
