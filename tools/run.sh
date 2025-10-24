#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
COMMAND=""
SROS_IMAGE="${SROS_CONTAINER_IMAGE:-}"
SROS_NAME="${SROS_CONTAINER_NAME:-sros-test}"
SROS_SSH_PORT="${SROS_SSH_PORT:-2222}"
SROS_NETCONF_PORT="${SROS_NETCONF_PORT:-2830}"
SROS_BOOT_TIMEOUT="${SROS_BOOT_TIMEOUT:-180}"
LICENSE_FILE="${SROS_LICENSE_FILE:-}"
EXTRA_DOCKER_ARGS=()
SROS_USERNAME="${SROS_USERNAME:-}"
SROS_PASSWORD="${SROS_PASSWORD:-}"
SROS_NETWORK_OS="${SROS_NETWORK_OS:-}"
SROS_CONTAINER_EXTRA_ARGS="${SROS_CONTAINER_EXTRA_ARGS:-}"

usage() {
  cat <<USAGE
Usage: $(basename "$0") <command> [args]

Commands:
  deps            Install Python dependencies into the current environment.
  sanity [args]   Run ansible-test sanity checks (additional args forwarded).
  build [args]    Build the collection artifact (forwards args to ansible-galaxy collection build).
  integration [args]
                  Run ansible-test integration against a containerised SR OS device.
  all             Run sanity, build, and integration in sequence.

Environment variables:
  PYTHON_VERSION           Python version used for ansible-test (default: 3.11)
  SROS_CONTAINER_IMAGE     Container image used for integration testing.
  SROS_CONTAINER_NAME      Name assigned to the SR OS container (default: sros-test).
  SROS_SSH_PORT            Local TCP port exposed for SSH (default: 2222).
  SROS_NETCONF_PORT        Local TCP port exposed for NETCONF (default: 2830).
  SROS_LICENSE_FILE        Path to a SR OS license file that will be mounted into the container.
  SROS_USERNAME            Username used by the integration tests (defaults to "admin" if unset).
  SROS_PASSWORD            Password used by the integration tests (defaults to "admin" if unset).
  SROS_NETWORK_OS          Network OS identifier (defaults to nokia.sros.classic).
  SROS_BOOT_TIMEOUT        Seconds to wait for the SR OS container to become reachable (default: 180).
  SROS_CONTAINER_EXTRA_ARGS
                           Additional docker arguments appended when starting the container.
USAGE
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

fail() {
  echo "[ERROR] $*" >&2
  exit 1
}

info() {
  echo "[INFO] $*" >&2
}

run_deps() {
  info "Installing Python dependencies"
  python -m pip install --upgrade pip
  pip install -r "$PROJECT_ROOT/requirements.txt"
}

run_sanity() {
  local args=("${COMMAND_ARGS[@]}")
  if [[ ${#args[@]} -eq 0 ]]; then
    args=("--python" "$PYTHON_VERSION")
  fi
  info "Running ansible-test sanity ${args[*]}"
  ansible-test sanity "${args[@]}"
}

run_build() {
  local args=("${COMMAND_ARGS[@]}")
  if [[ ${#args[@]} -eq 0 ]]; then
    args=("--output-path" "$PROJECT_ROOT/dist/")
  fi
  mkdir -p "$PROJECT_ROOT/dist"
  info "Building collection artifact"
  ansible-galaxy collection build "${args[@]}"
}

cleanup_container() {
  if docker ps -a --format '{{.Names}}' | grep -q "^${SROS_NAME}$"; then
    info "Stopping SR OS container ${SROS_NAME}"
    docker rm -f "$SROS_NAME" >/dev/null 2>&1 || true
  fi
}

wait_for_port() {
  local host="$1" port="$2" timeout="$3" waited=0
  python - "$host" "$port" "$timeout" <<'PY'
import socket
import sys
host = sys.argv[1]
port = int(sys.argv[2])
timeout = int(sys.argv[3])
import time
for elapsed in range(timeout):
    try:
        with socket.create_connection((host, port), timeout=1):
            sys.exit(0)
    except OSError:
        time.sleep(1)
print(f"Timed out waiting for {host}:{port} after {timeout}s", file=sys.stderr)
sys.exit(1)
PY
}

start_container() {
  [[ -n "$SROS_IMAGE" ]] || fail "SROS_CONTAINER_IMAGE is required for integration tests"
  command_exists docker || fail "docker is required for integration tests"

  cleanup_container

  info "Pulling SR OS container image ${SROS_IMAGE}"
  docker pull "$SROS_IMAGE"

  IFS=' ' read -r -a EXTRA_DOCKER_ARGS <<< "$SROS_CONTAINER_EXTRA_ARGS"

  local mount_args=()
  if [[ -n "$LICENSE_FILE" ]]; then
    [[ -f "$LICENSE_FILE" ]] || fail "License file $LICENSE_FILE does not exist"
    mount_args=(-v "$LICENSE_FILE:/license.key:ro" -e "LICENSE_FILE=/license.key")
  fi

  info "Starting SR OS container ${SROS_NAME}"
  docker run -d --rm \
    --name "$SROS_NAME" \
    -h "$SROS_NAME" \
    -p "${SROS_SSH_PORT}:22" \
    -p "${SROS_NETCONF_PORT}:830" \
    "${EXTRA_DOCKER_ARGS[@]}" \
    "${mount_args[@]}" \
    "$SROS_IMAGE"

  trap cleanup_container EXIT

  info "Waiting for SSH on port ${SROS_SSH_PORT}"
  wait_for_port "127.0.0.1" "$SROS_SSH_PORT" "$SROS_BOOT_TIMEOUT"
}

run_integration() {
  local args=("${COMMAND_ARGS[@]}")
  if [[ ${#args[@]} -eq 0 ]]; then
    args=("--python" "$PYTHON_VERSION")
  fi
  start_container
  export SROS_HOST="127.0.0.1"
  export SROS_SSH_PORT
  export SROS_NETCONF_PORT
  local username="$SROS_USERNAME"
  local password="$SROS_PASSWORD"
  if [[ -z "$username" ]]; then
    username="${ANSIBLE_NET_USERNAME:-admin}"
  fi
  if [[ -z "$password" ]]; then
    password="${ANSIBLE_NET_PASSWORD:-admin}"
  fi
  export ANSIBLE_NET_USERNAME="$username"
  export ANSIBLE_NET_PASSWORD="$password"
  export ANSIBLE_NET_AUTH_PASS="$password" # compatibility for older Ansible
  if [[ -n "$SROS_NETWORK_OS" ]]; then
    export ANSIBLE_NETWORK_OS="$SROS_NETWORK_OS"
  else
    export ANSIBLE_NETWORK_OS="${ANSIBLE_NETWORK_OS:-nokia.sros.classic}"
  fi

  info "Running ansible-test integration ${args[*]}"
  ansible-test integration "${args[@]}"
}

run_all() {
  run_sanity
  run_build
  run_integration
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    sanity|build|integration|deps|all)
      COMMAND="$1"
      shift
      break
      ;;
    *)
      fail "Unknown global argument: $1"
      ;;
  esac
done

[[ -n "$COMMAND" ]] || fail "A command is required. Run with --help for usage"

COMMAND_ARGS=()
if [[ $# -gt 0 ]]; then
  COMMAND_ARGS=("$@")
fi

case "$COMMAND" in
  deps)
    run_deps
    ;;
  sanity)
    run_sanity
    ;;
  build)
    run_build
    ;;
  integration)
    run_integration
    ;;
  all)
    run_all
    ;;
  *)
    fail "Unknown command: $COMMAND"
    ;;
esac
