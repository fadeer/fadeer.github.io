FROM ruby:2.6.6-alpine
RUN apk --update add --no-cache build-base
WORKDIR /blog
ADD Gemfile .
RUN bundle install

EXPOSE 4000
CMD ["bundle", "exec", "jekyll", "serve"]
