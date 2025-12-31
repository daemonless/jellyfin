ARG BASE_VERSION=15
FROM ghcr.io/daemonless/base:${BASE_VERSION}

ARG FREEBSD_ARCH=amd64
ARG PKG_NAME=jellyfin
ARG UPSTREAM_URL="https://api.github.com/repos/jellyfin/jellyfin/releases/latest"
ARG UPSTREAM_JQ=".tag_name"
ARG HEALTHCHECK_ENDPOINT="http://localhost:8096/health"

ENV HEALTHCHECK_URL="${HEALTHCHECK_ENDPOINT}"

LABEL org.opencontainers.image.title="Jellyfin" \
      org.opencontainers.image.description="The Free Software Media System on FreeBSD" \
      org.opencontainers.image.source="https://github.com/daemonless/jellyfin" \
      org.opencontainers.image.url="https://jellyfin.org/" \
      org.opencontainers.image.licenses="GPL-2.0-only" \
      org.opencontainers.image.vendor="daemonless" \
      org.opencontainers.image.authors="daemonless" \
      io.daemonless.port="8096" \
      io.daemonless.arch="${FREEBSD_ARCH}" \
      io.daemonless.pkg-name="${PKG_NAME}" \
      io.daemonless.pkg-source="containerfile" \
      io.daemonless.upstream-url="${UPSTREAM_URL}" \
      io.daemonless.upstream-jq="${UPSTREAM_JQ}" \
      io.daemonless.healthcheck-url="${HEALTHCHECK_ENDPOINT}"

# Install from FreeBSD packages
RUN pkg update && \
    pkg install -y ${PKG_NAME} && \
    mkdir -p /app /config /cache /media && \
    pkg rquery '%v' ${PKG_NAME} > /app/version && \
    pkg clean -ay && \
    rm -rf /var/cache/pkg/* /var/db/pkg/repos/* && \
    chown bsd:bsd /config /cache /media

# Copy service definition and init scripts
COPY root/ /
RUN chmod +x /etc/services.d/jellyfin/run /etc/cont-init.d/* 2>/dev/null || true

EXPOSE 8096
VOLUME /config /cache /media
