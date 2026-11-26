FROM ruby:4

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends cmake \
    && rm -rf /var/lib/apt/lists/*

COPY .tool-versions Gemfile Gemfile.lock LICENSE rsmp-validator.gemspec ./
COPY config config
COPY config/validator_example.yaml config/validator.yaml
COPY exe exe
COPY lib lib
COPY schemas schemas
COPY test test
RUN chmod 600 config/simulator/secure/*.private.key && bundle install
COPY fixtures fixtures
EXPOSE 13111
ENTRYPOINT [ "bundle", "exec", "rsmp-validator" ]
CMD [ "run", "test/site/core", "test/site/tlc" ]
