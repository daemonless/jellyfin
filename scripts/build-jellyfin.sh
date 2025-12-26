#!/bin/sh
# Build Jellyfin server and web outside of a container
# This is needed because .NET requires allow.mlock which isn't available in podman build jails

set -e

BUILD_DIR="${BUILD_DIR:-/tmp/jellyfin-build}"
OUTPUT_DIR="${OUTPUT_DIR:-./build-output}"

echo "==> Updating package repos..."
pkg update -f

echo "==> Installing build dependencies..."
pkg install -y dotnet node22 npm-node22 python311 git-lite

echo "==> Fetching latest Jellyfin version..."
VERSION=$(fetch -qo - "https://api.github.com/repos/jellyfin/jellyfin/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
echo "Building Jellyfin ${VERSION}"

echo "==> Cloning repositories..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
git clone --depth 1 --branch "${VERSION}" https://github.com/jellyfin/jellyfin.git "${BUILD_DIR}/jellyfin"
git clone --depth 1 --branch "${VERSION}" https://github.com/jellyfin/jellyfin-web.git "${BUILD_DIR}/jellyfin-web"

echo "==> Building jellyfin-web..."
cd "${BUILD_DIR}/jellyfin-web"
export NODE_OPTIONS="--max-old-space-size=2048"
sed -i '' 's/"sass-embedded": ".*"/"sass": "1.89.2"/' package.json
sed -i '' 's/"engines": {/"_engines": {/' package.json
npm install --ignore-engines
npm run build:production

echo "==> Building Jellyfin Server..."
cd "${BUILD_DIR}/jellyfin"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export DOTNET_PROCESSOR_COUNT=1
export COMPlus_EnableWriteXorExecute=0

dotnet publish Jellyfin.Server \
    --configuration Release \
    --output "${BUILD_DIR}/app" \
    --no-self-contained \
    "-p:DebugSymbols=false;DebugType=none;UseAppHost=false;PublishReadyToRun=false;Parallel=false"

echo "==> Combining web and server..."
mkdir -p "${BUILD_DIR}/app/jellyfin-web"
cp -r "${BUILD_DIR}/jellyfin-web/dist/"* "${BUILD_DIR}/app/jellyfin-web/"

echo "==> Copying to output directory..."
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"
cp -r "${BUILD_DIR}/app" "${OUTPUT_DIR}/"
echo "${VERSION}" > "${OUTPUT_DIR}/version"

echo "==> Build complete: ${OUTPUT_DIR}"
ls -la "${OUTPUT_DIR}"
