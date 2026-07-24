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

IMAGE_REF="sjambler/samphire:latest"
# This must match build-container.sh for Podman builds.
LOCAL_MANIFEST_REF="localhost/sjambler/samphire:build-manifest"
DESTINATION_REF="docker://docker.io/${IMAGE_REF}"

echo "Using ${CONTAINER_CLI}"

if [ "${CONTAINER_CLI}" = "podman" ]; then
  if ! podman manifest inspect "${LOCAL_MANIFEST_REF}" >/dev/null 2>&1; then
    echo "Error: local manifest ${LOCAL_MANIFEST_REF} was not found." >&2
    echo "Run ./build-container.sh first." >&2
    exit 1
  fi

  podman manifest push --all "$@" "${LOCAL_MANIFEST_REF}" "${DESTINATION_REF}"
else
  echo "Docker path: build-container.sh already pushes during docker buildx build --push." >&2
  echo "Nothing to do." >&2
fi
