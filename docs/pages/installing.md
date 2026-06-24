---
layout: page
title: Installation
permalink: /install/
parent: Getting Started
nav_order: 2
---

# Installation

## Prerequisites
Ruby, a dynamic language: https://www.ruby-lang.org/en/. Ruby 4.0.5 or newer is recommended because the validator uses the current `rsmp` gem. It's recommended to install Ruby using a version manager like [rbenv](https://github.com/rbenv/rbenv).

Bundler is used for for installing dependencies: https://bundler.io

Check that prerequisites are installed:

```
% ruby --version
ruby 4.0.5 (2026-05-20 revision 64336ffd0e) +PRISM [x86_64-darwin22]
% bundler --version
4.0.9
```

## Installing the gem
Install the packaged validator from RubyGems:

```console
% gem install rsmp-validator
```

You can then run the conformance tests with the `rsmp-validator` command.

## Installing from source
If you want to work on the validator itself, clone the Git repository and run Bundler:

```
# clone the rsmp_validator git repository to your local machine
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

You will now have sus, the rsmp gem and all other dependencies installed for the source checkout.

It's recommended to use [bundle exec](https://bundler.io/man/bundle-exec.1.html) when running commands from a source checkout, for example `bundle exec rsmp-validator run test/site`.
