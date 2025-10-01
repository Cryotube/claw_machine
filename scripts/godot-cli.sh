#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

resolve_godot_bin() {
  local candidate

  # 1. Respect GODOT_BIN if provided (can be command or path).
  if [[ -n "${GODOT_BIN:-}" ]]; then
    candidate="${GODOT_BIN}"
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
    if command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"
      return 0
    fi
    echo "ERROR: GODOT_BIN='$candidate' is not an executable or command" >&2
    exit 1
  fi

  # 2. Try common command names available on PATH.
  for candidate in godot4 godot; do
    if command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"
      return 0
    fi
  done

  # 3. Fall back to default macOS install path.
  candidate="/Applications/Godot.app/Contents/MacOS/Godot"
  if [[ -x "$candidate" ]]; then
    echo "$candidate"
    return 0
  fi

  echo "ERROR: Godot binary not found. Set GODOT_BIN or install Godot (expected at $candidate)." >&2
  exit 1
}

GODOT_BIN="$(resolve_godot_bin)"

# If no --path passed, default to repository root so Godot picks up project.godot.
if [[ " $* " != *" --path "* ]]; then
  set -- --path "$SCRIPT_DIR" "$@"
fi

exec "$GODOT_BIN" "$@"
