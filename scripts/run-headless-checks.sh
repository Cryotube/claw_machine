#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

run() {
  local description="$1"
  shift
  echo "==> $description"
  "$@"
  echo "✓ $description"
}

run "Running GUT unit tests" "$REPO_ROOT/scripts/godot-cli.sh" --headless --run res://tests/gut/test_runner.tscn
run "Running customer queue performance benchmark" "$REPO_ROOT/scripts/godot-cli.sh" --headless --run res://tests/perf/customer_queue_benchmark.tscn

echo "All headless checks passed"
