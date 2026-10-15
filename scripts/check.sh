#!/usr/bin/env bash
# Runs every check on the codebase: formatters, linters, type checks, speclint, and the tests.
# Every check runs even if an earlier one fails, and the script exits 1 if any failed. The Claude
# Code Stop hook (.claude/hooks/check-stop.sh) and CI both run it, so they check the same things.
#
# Usage: scripts/check.sh [--no-tests]
#   --no-tests  skip the tests (the Stop hook runs it this way; CI runs it without)

run_tests=1
for arg in "$@"; do
  case "$arg" in
    --no-tests) run_tests=0 ;;
    *) printf 'usage: scripts/check.sh [--no-tests]\n' >&2; exit 2 ;;
  esac
done

cd "$(dirname "$0")/.." || exit 2

failed=()

# check <name> <command...>: runs the command and records <name> as failed if it exits non-zero.
check() {
  local name=$1; shift
  local out
  if ! out=$("$@" 2>&1); then
    printf '\n== %s failed ==\n%s\n' "$name" "$out"
    failed+=("$name")
  fi
}

# speclint, from the tools/speclint submodule. Remove this line if the project doesn't use specs.
check speclint go run -C tools/speclint ./cmd/speclint -root ../..

# CUSTOMIZE: add the project's checks. Keep them fast enough to run at the end of every turn;
# anything slow belongs in the tests block below. Examples:
#   check gofmt test -z "$(gofmt -l .)"
#   check "go vet" go vet ./...
#   check tsc npx --no-install tsc --noEmit
#   check eslint npx --no-install eslint .
#   check ruff ruff check .
#   check mypy mypy .

if [ "$run_tests" -eq 1 ]; then
  # CUSTOMIZE: the project's tests. Examples:
  #   check "go test" go test ./...
  #   check "frontend tests" npm --prefix frontend test
  #   check pytest pytest -q
  :
fi

if [ ${#failed[@]} -gt 0 ]; then
  printf '\ncheck: %d failed: %s\n' "${#failed[@]}" "$(IFS=,; echo "${failed[*]}")"
  exit 1
fi
printf 'check: all passed\n'
