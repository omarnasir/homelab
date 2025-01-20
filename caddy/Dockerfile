ARG VERSION

FROM caddy:$VERSION-builder AS builder
RUN xcaddy build \
  --with github.com/caddy-dns/cloudflare

FROM caddy:$VERSION AS caddy
COPY --from=builder /usr/bin/caddy /usr/bin/caddy