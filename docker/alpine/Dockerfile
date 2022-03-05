FROM golang:alpine3.15

RUN go get github.com/ericchiang/pup
RUN go get github.com/simplealpine/yaml2json

FROM alpine:3.15.0

LABEL maintainer="Attila Fabrik, fabrik85@gmail.com"

WORKDIR /bin/
COPY --from=0 /go/bin/yaml2json .
COPY --from=0 /go/bin/pup .

RUN apk add --no-cache \
    curl \
    jq \
    bash \
    aws-cli \
    ncurses

# Infrastructure files
COPY docker/resource/mutt /root/.mutt

# Application files
COPY config.yml helper.sh main.sh /home/src/
COPY actions /home/src/actions

# ENTRYPOINT
COPY docker/docker-entrypoint.sh /usr/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["help"]
