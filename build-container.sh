#!/usr/bin/env sh
set -eu

# Prefer Podman; fall back to Docker.
if command -v podman >/dev/null 2>&1; then
  CONTAINER_CLI="podman"
elif command -v docker >/dev/null 2>&1; then
  CONTAINER_CLI="docker"
else
  echo "Error: neither podman nor docker was found on PATH." >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git was not found on PATH." >&2
  exit 1
fi

echo "Using ${CONTAINER_CLI}"

IMAGE_REF="sjambler/samphire:latest"
# Keep the local manifest name separate from publish tags to avoid collisions
# with single-arch images (local or remote) named sjambler/samphire:latest.
LOCAL_MANIFEST_REF="localhost/sjambler/samphire:build-manifest"

# Build a source bundle from the current HEAD commit so it is copied with
# other static resources into the image at static/samphire/src/samphire.zip.
SOURCE_ARCHIVE_DIR="basex/static/src"
SOURCE_ARCHIVE_PATH="${SOURCE_ARCHIVE_DIR}/samphire.zip"
mkdir -p "${SOURCE_ARCHIVE_DIR}"
git archive --format=zip --output="${SOURCE_ARCHIVE_PATH}" HEAD

if [ "${CONTAINER_CLI}" = "podman" ]; then
  # Recreate a clean local manifest each run to avoid stale image references.
  podman manifest rm "${LOCAL_MANIFEST_REF}" >/dev/null 2>&1 || true
  podman manifest create "${LOCAL_MANIFEST_REF}"

  # Build the production image (webapp stage) and add to the local manifest.
  podman build \
    --platform linux/arm64/v8,linux/amd64/v4 \
    --target webapp \
    --manifest "${LOCAL_MANIFEST_REF}" \
    "$@" .

  echo
  echo "Build complete. Push with:"
  echo "  podman manifest push --all ${LOCAL_MANIFEST_REF} docker://docker.io/${IMAGE_REF}"
else
  # Docker requires buildx for multi-platform builds and must push directly to
  # a registry (no local multi-platform manifest store is available).
  docker buildx build \
    --platform linux/arm64/v8,linux/amd64/v4 \
    --target webapp \
    --tag "${IMAGE_REF}" \
    --push \
    "$@" .
fi
