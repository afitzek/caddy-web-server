#
# This file is derived from: https://github.com/abiosoft/caddy-docker/blob/c79574ed6045a53719304fb54082b904aa1756c1/Dockerfile
#

#
# Builder
#

#
# switch back to abiosoft when cloudflare plugin problem is solved
# https://github.com/abiosoft/caddy-docker/issues/151
# FROM abiosoft/caddy:builder as builder
#

FROM grugnog/caddy-docker:builder as builder

ARG version="0.11.1"

# check docker plugin when there is time
ARG plugins=prometheus,realip,upload,grpc,cloudflare,net

# process wrapper
RUN go get -v github.com/abiosoft/parent

RUN ENABLE_TELEMETRY=false VERSION=${version} PLUGINS=${plugins} /bin/sh /usr/bin/builder.sh

#
# Final stage
#
FROM alpine:3.8

LABEL caddy_version="0.11.1"

# Telemetry Stats
ENV ENABLE_TELEMETRY="false"

# Let's Encrypt Agreement
ENV ACME_AGREE="true"

RUN apk add --no-cache openssh-client git tar curl

# install caddy
COPY --from=builder /install/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

EXPOSE 80 443 2015
VOLUME /caddy/config
VOLUME /caddy/log
VOLUME /caddy/srv
WORKDIR /caddy

# install process wrapper
COPY --from=builder /go/bin/parent /bin/parent

ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/caddy/config/Caddyfile", "--agree", "--log", "stdout"]
