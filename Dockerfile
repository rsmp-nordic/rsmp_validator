FROM ruby:latest
COPY . .
RUN bundle install
EXPOSE 12111
ENTRYPOINT [ "bundle", "exec", "rspec" ]
CMD [ "spec/site/core", "spec/site/tlc" ]
