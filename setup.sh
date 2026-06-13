#!/usr/bin/env bash
# setup.sh — install the Chatterbox voice engine into a local venv and put
# `clone` on your PATH. The model itself downloads on first run.
#
#   ./setup.sh            create .venv, install chatterbox-tts + torch, link clone
#   ./setup.sh --cpu      install CPU-only torch (no NVIDIA GPU)
#   ./setup.sh --check    show what would happen, change nothing
#
# https://github.com/CastilloworksAi/clone   (MIT)
set -euo pipefail

DRYRUN=0; CPU=0
for a in "$@"; do
  case "$a" in
    --check|--dry-run) DRYRUN=1 ;;
    --cpu) CPU=1 ;;
    *) echo "unknown arg: $a" >&2; exit 2 ;;
  esac
done

c_reset=$'\033[0m'; c_grn=$'\033[32m'; c_dim=$'\033[2m'
ok()  { printf '%s✓%s %s\n' "$c_grn" "$c_reset" "$*"; }
run() { if [[ $DRYRUN -eq 1 ]]; then printf '%swould run:%s %s\n' "$c_dim" "$c_reset" "$*"; else eval "$*"; fi; }
have(){ command -v "$1" >/dev/null 2>&1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINDIR="${HOME}/.local/bin"
VENV="$SCRIPT_DIR/.venv"
PY="$VENV/bin/python"

have python3 || { echo "python3 (3.10+) is required." >&2; exit 1; }
ok "python3 present"

run "python3 -m venv '$VENV'"
if [[ $CPU -eq 1 ]]; then
  run "'$PY' -m pip install --upgrade pip torch torchaudio --index-url https://download.pytorch.org/whl/cpu"
else
  run "'$PY' -m pip install --upgrade pip torch torchaudio"
fi
run "'$PY' -m pip install chatterbox-tts"
ok "engine installed into .venv"

run "mkdir -p '$BINDIR'"
run "ln -sf '$SCRIPT_DIR/clone' '$BINDIR/clone'"
run "chmod +x '$SCRIPT_DIR/clone' '$SCRIPT_DIR/clone.py'"
ok "linked clone -> $BINDIR/clone"

case ":$PATH:" in
  *":$BINDIR:"*) ok "$BINDIR is on your PATH" ;;
  *) printf '\nAdd to your shell rc:\n  export PATH="%s:$PATH"\n' "$BINDIR" ;;
esac

if [[ $DRYRUN -eq 0 ]]; then
  echo; "$SCRIPT_DIR/clone" --check || true
  printf '\nTry it:  %sclone "hello from a clone" --voice some_voice.wav%s\n' "$c_dim" "$c_reset"
fi
