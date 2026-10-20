#!/bin/bash
set -eu

source "build.cfg"
source "VERSION"

RUN_ARGS=()

# Forward the SSH agent if one is running.
if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
  RUN_ARGS+=(-e "SSH_AUTH_SOCK=${SSH_AUTH_SOCK}" -v "${SSH_AUTH_SOCK}:${SSH_AUTH_SOCK}")
fi

# Docker Desktop on macOS exposes the raw socket inside its VM. On Linux,
# also join the socket's group since its gid differs from the image's.
if [[ "$(uname)" == "Darwin" ]]; then
  RUN_ARGS+=(-v /var/run/docker.sock.raw:/var/run/docker.sock)
elif [[ -S /var/run/docker.sock ]]; then
  RUN_ARGS+=(-v /var/run/docker.sock:/var/run/docker.sock --group-add "$(stat -c %g /var/run/docker.sock)")
fi

# Only mount host configs that exist, otherwise Docker creates them as
# root owned directories.
for path in .ssh .kube .aws .zhistory .docker; do
  if [[ -e "${HOME}/${path}" ]]; then
    RUN_ARGS+=(-v "${HOME}/${path}:/home/${BUILD_USER}/${path}")
  fi
done

docker run -d \
  --restart unless-stopped \
  "${RUN_ARGS[@]}" \
  -v "${IMAGE_NAME}:/home/${BUILD_USER}" \
  -p "${SSH_PORT:-2222}:22" \
  -p "${CODE_SERVER_PORT:-8443}:8443" \
  --hostname="${IMAGE_NAME}" \
  --name "${IMAGE_NAME}" "${IMAGE_NAME}:latest"
