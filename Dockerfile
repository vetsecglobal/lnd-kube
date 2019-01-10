FROM golang:1.11-alpine as builder

MAINTAINER Olaoluwa Osuntokun <lightning.engineering>


# Install build dependencies such as git and glide.
#RUN apk add --no-cache git

# Copy in the local repository to build from.
#COPY . /go/src/github.com/lightningnetwork/lnd

#WORKDIR $GOPATH/src/github.com/lightningnetwork/lnd

#RUN git clone https://github.com/lightningnetwork/lnd.git /go/src/github.com/lightningnetwork/lnd

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

#RUN echo http://mirror.yandex.ru/mirrors/alpine/v3.5/main > /etc/apk/repositories; \
#    echo http://mirror.yandex.ru/mirrors/alpine/v3.5/community >> /etc/apk/repositories

# Install dependencies and install/build lnd.

#RUN apk update \
#&&  apk add --no-cache \
RUN sed -i -e 's/dl-cdn/dl-4/' /etc/apk/repositories && \
    apk add --no-cache \
        bash \
        build-base \
    git \
    make \
&&  pwd \
&&  git clone https://github.com/lightningnetwork/lnd.git /go/src/github.com/lightningnetwork/lnd \
&&  ls \
&&  cd /go/src/github.com/lightningnetwork/lnd \
&&  pwd \
&&  ls \
&&  go get -d ./... \
&&  make \
&&  make install

# Start a new, final image to reduce size.
FROM alpine as final

# Expose lnd ports (server, rpc).
EXPOSE 9735 10009

# Copy the binaries and entrypoint from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/

# Add bash.
RUN apk add --no-cache \
    bash

# Copy the entrypoint script.
#COPY "docker/lnd/start-lnd.sh" .
#COPY "start-lnd.sh" .
RUN chmod +x /go/src/github.com/lightningnetwork/lnd/docker/lnd/start-lnd.sh

ENTRYPOINT ["/go/src/github.com/lightningnetwork/lnd/docker/lnd/start-lnd.sh"]
