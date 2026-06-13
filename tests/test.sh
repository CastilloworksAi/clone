#!/usr/bin/env bash
# Dependency-light tests for clone. No model, no torch, no GPU:
# the engine imports lazily, so check/dry-run/help/arg-handling all work and
# are verified here. (Actual synthesis runs on your GPU — see README.)
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0; fail=0
c_grn=$'\033[32m'; c_red=$'\033[31m'; c_reset=$'\033[0m'
ok()  { printf '%s✓%s %s\n' "$c_grn" "$c_reset" "$1"; pass=$((pass+1)); }
bad() { printf '%s✗%s %s\n' "$c_red" "$c_reset" "$1"; fail=$((fail+1)); }
contains(){ case "$3" in *"$2"*) ok "$1";; *) bad "$1 (missing '$2')";; esac; }
py(){ python3 "$ROOT/clone.py" "$@"; }

echo "== syntax =="
for f in "$ROOT/clone" "$ROOT/setup.sh" "$ROOT/tests/test.sh"; do
  if bash -n "$f"; then ok "bash -n $(basename "$f")"; else bad "bash -n $(basename "$f")"; fi
done
if python3 -m py_compile "$ROOT/clone.py"; then ok "clone.py compiles"; else bad "clone.py compile error"; fi

echo "== lazy import: CLI works without the engine =="
contains "help works"      "voice cloning" "$(py --help 2>&1)"
# --check should RUN (and report engine missing) without crashing the interpreter
out="$(py --check 2>&1 || true)"
contains "check reports torch"      "torch"      "$out"
contains "check reports chatterbox" "chatterbox" "$out"

echo "== --dry-run builds a plan (no model) =="
out="$(py 'hello from a clone' --voice ref.wav --out v.wav --device cpu --dry-run)"
contains "plan: text"   "hello from a clone" "$out"
contains "plan: voice"  "ref.wav"            "$out"
contains "plan: out"    "v.wav"              "$out"
contains "plan: device" "cpu"                "$out"
# default-voice path (no --voice) is allowed
contains "plan: default voice ok" "default voice" "$(py 'hi' --device cpu --dry-run)"

echo "== arg handling =="
if py --dry-run >/dev/null 2>&1; then bad "missing text should fail"; else ok "missing text exits nonzero"; fi
if py 'hi' --device bogus --dry-run >/dev/null 2>&1; then bad "bad device should fail"; else ok "bad --device exits nonzero"; fi
# missing reference file should fail (only in real run, not dry-run)
if py 'hi' --voice /no/such.wav >/dev/null 2>&1; then bad "missing ref should fail"; else ok "missing ref audio exits nonzero"; fi

echo "== setup.sh dry-run =="
if "$ROOT/setup.sh" --check >/dev/null 2>&1; then ok "setup.sh --check clean"; else bad "setup.sh --check failed"; fi
if "$ROOT/setup.sh" --cpu --check >/dev/null 2>&1; then ok "setup.sh --cpu --check clean"; else bad "setup.sh --cpu --check failed"; fi

echo
printf 'passed %d, failed %d\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
