# Installing
## Setups
If you're testing physical equipment like a traffic light controller, you will typically install the validator it on a separate machine. The site will then connect to the validator via network.

But for development, it can be useful to install the validator on the same machine as the RSMP implementation you're working on. The site can then connect to the validator on the local machine.

## Prerequisites
### Git
Git is used to fetch and update tools, dependencies, etc. For installation instructions, see https://git-scm.com/downloads

Check that git is installed:

```sh
% git --version
git version 2.31.1
```

### Ruby
The RSMP Validator is based on Ruby, a dynamic language. It's recommended to install Ruby using a version manager like [rbenv](https://github.com/rbenv/rbenv). 

Check that Ruby is installed:

```sh
% ruby --version
ruby 3.0.0p0 (2020-12-25 revision 95aff21468) [x86_64-darwin20]
```

### Bundler
Bundler is a popular package manager for Ruby. For installation instructions, see https://bundler.io

Check that Bundler is installed:

```sh
% bundler --version
Bundler version 2.2.15
```

## Installing
The easiest way to install the validator is to clone the respository on GitHub repository, using the git command.

```sh
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

You will now have RSpec and all other dependencies installed.

It's recommended to use ```bundle exec```to run rspec and other commands that come from gems, to ensure you're using the correct version of the gems. See https://bundler.io/man/bundle-exec.1.html
