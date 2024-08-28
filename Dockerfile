FROM ruby:latest
COPY .tool-versions .rspec Gemfile Gemfile.lock LICENSE ./
COPY spec spec
RUN bundle install
EXPOSE 13111
ENTRYPOINT [ "bundle", "exec", "rspec" ]
CMD [ "spec/site/core", "spec/site/tlc" ]
