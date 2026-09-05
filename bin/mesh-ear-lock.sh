#!/usr/bin/env bash
# mesh-ear-lock.sh — sourceable flock helpers for single-ear TTS across hosts.
# Usage: source mesh-ear-lock.sh && mesh_ear_acquire && … && mesh_ear_release

set -euo pipefail

MESH_EAR_LOCKFILE="${MESH_EAR_LOCKFILE:-$HOME/.local/share/pycoach-tts/mesh-ear.lock}"
MESH_EAR_HOST="${MESH_EAR_HOST:-pop-os}"

_mesh_ear_hostname() {
  local h
  h="$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo unknown)"
  h="${h%%.*}"
  printf '%s' "$h"
}

_mesh_ear_is_ear_machine() {
  local h="$(_mesh_ear_hostname)"
  [[ "$h" == "pop-os" || "$h" == "thinkpad" ]]
}

_mesh_ear_is_local() {
  local h="$(_mesh_ear_hostname)"

  if _mesh_ear_is_ear_machine; then
    return 0
  fi

  if [[ -n "${MESH_EAR_HOST:-}" && "$MESH_EAR_HOST" == "$h" ]]; then
    return 0
  fi

  if [[ -z "${MESH_EAR_HOST:-}" ]] && _mesh_ear_is_ear_machine; then
    return 0
  fi

  if [[ ! -v MESH_EAR_HOST ]] && _mesh_ear_is_ear_machine; then
    return 0
  fi

  return 1
}

mesh_ear_acquire() {
  mkdir -p "$(dirname "$MESH_EAR_LOCKFILE")"
  : >> "$MESH_EAR_LOCKFILE"

  echo "… warte auf Mesh-Ohr (eine Spur)" >&2

  if _mesh_ear_is_local; then
    MESH_EAR_MODE=local
    exec {MESH_EAR_FD}>>"$MESH_EAR_LOCKFILE"
    flock -x "$MESH_EAR_FD"
    export MESH_EAR_FD MESH_EAR_MODE
    return 0
  fi

  MESH_EAR_MODE=remote
  MESH_EAR_TOKEN="mesh-ear-$$-$(date +%s%N 2>/dev/null || date +%s)"
  MESH_EAR_REMOTE_READY="/tmp/${MESH_EAR_TOKEN}.ready"
  MESH_EAR_REMOTE_HOLD="/tmp/${MESH_EAR_TOKEN}.hold"

  ssh -o BatchMode=yes -o ConnectTimeout=15 -o ServerAliveInterval=30 \
    "$MESH_EAR_HOST" bash -s -- "$MESH_EAR_TOKEN" "$MESH_EAR_LOCKFILE" <<'REMOTE' &
set -euo pipefail
token="$1"
lockfile="$2"
ready="/tmp/${token}.ready"
hold="/tmp/${token}.hold"
mkdir -p "$(dirname "$lockfile")"
: >> "$lockfile"
(
  flock -x 200
  touch "$ready"
  touch "$hold"
  while [[ -f "$hold" ]]; do
    sleep 0.25
  done
  rm -f "$ready" "$hold"
) 200<>"$lockfile"
REMOTE
  MESH_EAR_SSH_PID=$!

  local waited=0
  while ! ssh -o BatchMode=yes -o ConnectTimeout=5 \
    "$MESH_EAR_HOST" "test -f '$MESH_EAR_REMOTE_READY'" 2>/dev/null; do
    if ! kill -0 "$MESH_EAR_SSH_PID" 2>/dev/null; then
      echo "mesh-ear: SSH-Sperre auf $MESH_EAR_HOST fehlgeschlagen" >&2
      wait "$MESH_EAR_SSH_PID" 2>/dev/null || true
      return 1
    fi
    sleep 0.25
    waited=$((waited + 1))
    if (( waited > 600 )); then
      echo "mesh-ear: Zeitüberschreitung beim Warten auf $MESH_EAR_HOST" >&2
      mesh_ear_release
      return 1
    fi
  done

  export MESH_EAR_MODE MESH_EAR_TOKEN MESH_EAR_HOST MESH_EAR_SSH_PID
  export MESH_EAR_REMOTE_READY MESH_EAR_REMOTE_HOLD
}

mesh_ear_release() {
  case "${MESH_EAR_MODE:-}" in
    local)
      if [[ -n "${MESH_EAR_FD:-}" ]]; then
        flock -u "$MESH_EAR_FD" 2>/dev/null || true
        eval "exec ${MESH_EAR_FD}>&-" 2>/dev/null || true
      fi
      unset MESH_EAR_FD MESH_EAR_MODE
      ;;
    remote)
      if [[ -n "${MESH_EAR_HOST:-}" && -n "${MESH_EAR_REMOTE_HOLD:-}" ]]; then
        ssh -o BatchMode=yes -o ConnectTimeout=10 \
          "$MESH_EAR_HOST" "rm -f '$MESH_EAR_REMOTE_HOLD'" 2>/dev/null || true
      fi
      if [[ -n "${MESH_EAR_SSH_PID:-}" ]]; then
        wait "$MESH_EAR_SSH_PID" 2>/dev/null || true
      fi
      unset MESH_EAR_MODE MESH_EAR_TOKEN MESH_EAR_HOST MESH_EAR_SSH_PID
      unset MESH_EAR_REMOTE_READY MESH_EAR_REMOTE_HOLD
      ;;
  esac
}
