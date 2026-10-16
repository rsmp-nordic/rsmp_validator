FROM ruby:4

WORKDIR /app

COPY .tool-versions Gemfile Gemfile.lock LICENSE rsmp-validator.gemspec ./
COPY config config
COPY config/validator_example.yaml config/validator.yaml
COPY exe exe
COPY lib lib
COPY schemas schemas
COPY test test
RUN bundle install
COPY fixtures fixtures
EXPOSE 13111
ENTRYPOINT [ "bundle", "exec", "rsmp-validator" ]
CMD [ "run", "test/site/core", "test/site/tlc" ]
