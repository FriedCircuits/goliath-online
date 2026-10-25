#!/bin/bash
# Start an image and check the tools and services in it work.
# Usage: scripts/smoke-test.sh <image>
set -u

IMAGE="${1:?usage: $0 <image>}"
NAME="goliath-smoke-$$"
FAILED=0

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1
}
trap cleanup EXIT

check() {
  local label="$1"
  shift
  local output
  if output=$(docker exec "$NAME" zsh -lic "$*" 2>&1); then
    printf 'ok    %-15s %s\n' "$label" "$(echo "$output" | grep -v '^\s*$' | head -1)"
  else
    printf 'FAIL  %-15s %s\n' "$label" "$(echo "$output" | tail -1)"
    FAILED=1
  fi
}

docker run -d --name "$NAME" "$IMAGE" >/dev/null

# The entrypoint prints the code-server line once it is listening.
for _ in $(seq 1 90); do
  docker logs "$NAME" 2>&1 | grep -q "code-server:" && break
  sleep 1
done
docker logs "$NAME" 2>&1 | grep "code-server:"

check age "age --version"
check atuin "atuin --version"
check aws "aws --version"
check claude "claude --version"
check claude-rc "command -v claude-rc"
check codex "codex --version"
check direnv "direnv version"
check docker "docker --version"
check fnm "fnm --version"
check gh "gh --version"
check helm "helm version --short"
check k9s "k9s version --short"
check kubectl "kubectl version --client"
check node "node --version"
check sops "sops --version"
check talosctl "talosctl version --client --short"
check terraform "terraform version"
check terraform-docs "terraform-docs --version"
check terragrunt "terragrunt --version"
check tflint "tflint --version"
check tfswitch "tfswitch --version"
check uv "uv --version"
check yq "yq --version"
check github-hosts "grep -c github.com /etc/ssh/ssh_known_hosts"
check sshd "timeout 3 bash -c '</dev/tcp/127.0.0.1/22' && echo listening"
check code-server "curl -sk -o /dev/null -w '%{http_code}' https://127.0.0.1:8443/ | grep 302"

exit "$FAILED"
