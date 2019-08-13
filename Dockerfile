FROM ruby:alpine
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ARG ENVIRONMENT

RUN apk add --no-cache ruby-dev

COPY Gemfile /
RUN if [ "$ENVIRONMENT"  == "test" ]; \
    then \
      bundle install; \
    else \
      bundle install --without test; \
    fi;

COPY . /app
WORKDIR /app
ENTRYPOINT [ "ruby", "forwarder.rb" ]

