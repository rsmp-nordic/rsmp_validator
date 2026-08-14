FROM ruby:4

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends cmake \
    && rm -rf /var/lib/apt/lists/*

COPY .tool-versions Gemfile Gemfile.lock LICENSE rsmp-validator.gemspec ./
COPY config config
COPY exe exe
COPY lib lib
COPY schemas schemas
COPY test test
RUN bundle install
EXPOSE 13111
ENTRYPOINT [ "bundle", "exec", "rsmp-validator" ]
CMD [ "run", "test/site/core", "test/site/tlc" ]
