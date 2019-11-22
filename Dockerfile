FROM alpine:3.10

MAINTAINER Andreas Schulze <asl@iaean.net>

RUN apk --no-cache add tini coreutils \
        bash less man busybox-extras joe bind-tools \
        curl wget ca-certificates && \
    apk --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main add \
        protobuf fstrm && \
    apk --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community add \
 	dnsdist 're2<2019.11.01-r0' && \
    rm -rf /var/cache/apk/*

ENV MO_VERSION="2.1.0"
RUN curl -fsSL https://github.com/tests-always-included/mo/archive/$MO_VERSION.tar.gz | \
      tar -xO -zf- mo-$MO_VERSION/mo > /mo && \
    chmod a+x /mo

WORKDIR /root/

COPY dnsdist.conf /etc/dnsdist.mustache
COPY docker-entrypoint.sh /entrypoint.sh

EXPOSE 53/udp 53/tcp 5199/tcp 8053/tcp

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
CMD ["/usr/bin/dnsdist", "--disable-syslog", "--supervised"]
