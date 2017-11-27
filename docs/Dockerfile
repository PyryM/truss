# Slate Docker
# Adapted from: https://github.com/lord/slate/wiki/Docker
FROM ruby:2.3-alpine

RUN apk add --update nodejs g++ make git
RUN git clone --depth 1 https://github.com/lord/slate /usr/src/app
RUN cd /usr/src/app && bundle install

VOLUME /usr/src/app
WORKDIR /usr/src/app
EXPOSE 4567

CMD ["bundle", "exec", "middleman", "server", "--watcher-force-polling"]
