---
layout: page
title: Installing
permalink: /install/
parent: Get Started
nav_order: 1
---

# Installing
## Prerequisites
Git is used to fetch and update tools, dependencies, etc: https://git-scm.com/downloads

Ruby, a dynamic language: https://www.ruby-lang.org/en/. It's recommended to install Ruby using a version manager like [rbenv](https://github.com/rbenv/rbenv). 

Bundler is a popular package manager for Ruby: https://bundler.io

Check that prerequisites are installed:

```
% git --version
git version 2.31.1

% ruby --version
ruby 3.0.0p0 (2020-12-25 revision 95aff21468) [x86_64-darwin20]

% bundler --version
Bundler version 2.2.15
```

## Installing
Install by cloning the Git repository, and then running Bundler:

```
# clone the rsmp_validator git repository to you local machine
% git clone https://github.com/rsmp-nordic/rsmp_validator.git
Cloning into 'rsmp_validator'...
remote: Enumerating objects: 2097, done.
...

# move to the newly created project folder
% cd rsmp_validator

# use Bundler to install required Gems 
% bundle 
Using concurrent-ruby 1.1.7
Using i18n 1.8.7
...
Bundle complete! 4 Gemfile dependencies, 28 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.
```

You will now have RSpec, the rsmp gem and all other dependencies installed.

It's recommended to use [bundle exec](https://bundler.io/man/bundle-exec.1.html) to run `rspec` and other commands that come from gems, to ensure that you're using the correct version of the gems.
