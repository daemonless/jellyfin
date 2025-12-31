# Jellyfin container - expects pre-built artifacts in build-output/
# Run scripts/build-jellyfin.sh first (requires bare metal, not jail)
ARG BASE_VERSION=15
FROM ghcr.io/daemonless/arr-base:${BASE_VERSION}

ARG FREEBSD_ARCH=amd64
ARG PACKAGES="ffmpeg fontconfig freetype2 mediainfo libskiasharp"
ARG UPSTREAM_URL="https://api.github.com/repos/jellyfin/jellyfin/releases/latest"
ARG UPSTREAM_SED="s/.*\"tag_name\":\"\\([^\"]*\\)\".*/\\1/p"

LABEL org.opencontainers.image.title="Jellyfin" \
    org.opencontainers.image.description="The Free Software Media System on FreeBSD" \
    org.opencontainers.image.source="https://github.com/daemonless/jellyfin" \
    org.opencontainers.image.url="https://jellyfin.org/" \
    org.opencontainers.image.documentation="https://jellyfin.org/docs/" \
    org.opencontainers.image.licenses="GPL-2.0-only" \
    org.opencontainers.image.vendor="daemonless" \
    org.opencontainers.image.authors="daemonless" \
    io.daemonless.port="8096" \
    io.daemonless.arch="${FREEBSD_ARCH}" \
    org.freebsd.jail.allow.mlock="required" \
    io.daemonless.category="Media Servers" \
    io.daemonless.upstream-url="${UPSTREAM_URL}" \
    io.daemonless.upstream-sed="${UPSTREAM_SED}" \
    io.daemonless.packages="${PACKAGES}"

# Runtime dependencies
RUN pkg update && \
    pkg install -y ${PACKAGES} && \
    pkg clean -ay && \
    rm -rf /var/cache/pkg/* /var/db/pkg/repos/*

# Copy pre-built Jellyfin (built outside container due to .NET mlock requirement)
# Uses /usr/local/jellyfin to match :pkg image for config compatibility
COPY --chown=bsd:bsd build-output/app /usr/local/jellyfin
COPY --chown=bsd:bsd build-output/version /app/version

# Create directories
RUN mkdir -p /config /cache /media && \
    chown bsd:bsd /config /cache /media

# Copy service definition
COPY root/ /

RUN chmod +x /etc/services.d/jellyfin/run /etc/cont-init.d/* 2>/dev/null || true

EXPOSE 8096
VOLUME /config /cache /media
