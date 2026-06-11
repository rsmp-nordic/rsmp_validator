FROM ruby:latest
COPY .tool-versions Gemfile Gemfile.lock LICENSE ./
COPY spec spec
RUN bundle install
EXPOSE 13111
ENTRYPOINT [ "bundle", "exec", "sus" ]
CMD [ "test/site/core", "test/site/tlc" ]
