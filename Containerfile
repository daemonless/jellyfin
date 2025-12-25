ARG BASE_VERSION=15
FROM ghcr.io/daemonless/arr-base:${BASE_VERSION} AS builder

LABEL org.freebsd.jail.allow.mlock="required"

# Install build dependencies
RUN pkg update && \
    pkg install -y \
    dotnet \
    node22 \
    npm-node22 \
    python311 \
    git-lite

# Fetch latest version and clone Jellyfin
RUN VERSION=$(fetch -qo - "https://api.github.com/repos/jellyfin/jellyfin/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p') && \
    echo "Building Jellyfin ${VERSION}" && \
    git clone --depth 1 --branch ${VERSION} https://github.com/jellyfin/jellyfin.git /src/jellyfin && \
    git clone --depth 1 --branch ${VERSION} https://github.com/jellyfin/jellyfin-web.git /src/jellyfin-web && \
    echo "${VERSION}" > /app_version

# Build jellyfin-web
WORKDIR /src/jellyfin-web
ENV NODE_OPTIONS="--max-old-space-size=2048"
RUN sed -i '' 's/"sass-embedded": ".*"/"sass": "1.89.2"/' package.json && \
    sed -i '' 's/"engines": {/"_engines": {/' package.json && \
    npm install --ignore-engines && \
    npm run build:production

# Build Jellyfin Server
WORKDIR /src/jellyfin
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    DOTNET_PROCESSOR_COUNT=1 \
    COMPlus_EnableWriteXorExecute=0
RUN dotnet publish Jellyfin.Server \
    --configuration Release \
    --output /app \
    --self-contained \
    --runtime freebsd-x64 \
    "-p:DebugSymbols=false;DebugType=none;UseAppHost=true;PublishReadyToRun=false;Parallel=false"

# Combine web and server
RUN mkdir -p /app/jellyfin-web && \
    cp -r /src/jellyfin-web/dist/* /app/jellyfin-web/

# Final Stage
FROM ghcr.io/daemonless/arr-base:${BASE_VERSION}

ARG FREEBSD_ARCH=amd64
ARG PACKAGES="ffmpeg fontconfig freetype2 mediainfo libskiasharp"

LABEL io.daemonless.wip="true" \
    org.opencontainers.image.title="jellyfin" \
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
    io.daemonless.upstream-mode="github" \
    io.daemonless.upstream-repo="jellyfin/jellyfin" \
    io.daemonless.packages="${PACKAGES}"

# Runtime dependencies (ffmpeg, graphics, and mediainfo)
RUN pkg update && \
    pkg install -y \
    ${PACKAGES} && \
    pkg clean -ay && \
    rm -rf /var/cache/pkg/* /var/db/pkg/repos/*

COPY --from=builder /app /usr/local/share/jellyfin
COPY --from=builder /app_version /app/version

# Create config directory
RUN mkdir -p /config /cache /media && \
    chown -R bsd:bsd /config /cache /media

# Copy service definition and init scripts
COPY root/ /

# Make scripts executable
RUN chmod +x /etc/services.d/jellyfin/run /etc/cont-init.d/* 2>/dev/null || true

EXPOSE 8096
VOLUME /config /cache /media
