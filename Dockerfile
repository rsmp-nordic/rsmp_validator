FROM ruby:latest
COPY .ruby-version .rspec Gemfile Gemfile.lock LICENSE ./
COPY spec spec
RUN bundle install
EXPOSE 13111
ENTRYPOINT [ "bundle", "exec", "rspec" ]		# default executable
CMD [ "spec/site/core", "spec/site/tlc" ]		# default arguments
