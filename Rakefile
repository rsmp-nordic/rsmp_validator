# frozen_string_literal: true

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

# Note that rebuilding with YARD does not delete unused files.
# For this reason, it's often a good idea to delete the output folder before rebuilding, using:
# % rm -r docs/dev
desc 'Rebuild YARD docs for the RSpec files in spec.'
task :spec_docs do
  system 'bundle exec yardoc --template jekyll --format markdown --output docs/dev'
end
