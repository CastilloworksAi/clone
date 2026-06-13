# clone 🎙️

[![ci](https://github.com/CastilloworksAi/clone/actions/workflows/ci.yml/badge.svg)](https://github.com/CastilloworksAi/clone/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Make anything say anything — in any voice — on your own GPU.** Zero-shot voice
cloning from a few seconds of reference audio, powered by
[Chatterbox](https://github.com/resemble-ai/chatterbox) (MIT). No account, no
per-character billing, no audio leaving your machine.

```bash
clone "hey, welcome back to the channel" --voice me.wav
clone "subscribe for more" --voice me.wav --out intro.wav
clone "no reference? you still get a clean default voice"
```

Give it ~5–15 seconds of clean speech as `--voice`, and it speaks your text in
that voice.

---

## Quick start

```bash
git clone https://github.com/CastilloworksAi/clone.git
cd clone
./setup.sh            # creates .venv, installs the engine (CPU: ./setup.sh --cpu)
clone --check         # confirm the engine is ready
clone "this is my cloned voice" --voice sample.wav
```

> **First run downloads the model** (~1–2 GB) and is slow while it loads; runs
> after that are fast, especially on an NVIDIA GPU.

## Usage

| Flag | Default | Meaning |
|---|---|---|
| `--voice PATH` | none | reference audio to clone (wav/mp3, ~5–15s, clean) |
| `--out PATH` | `clone-out.wav` | where the result is saved |
| `--device` | `auto` | `auto`/`cuda`/`mps`/`cpu` |
| `--exaggeration` | `0.5` | expressiveness, 0–1 |
| `--cfg-weight` | `0.5` | pacing / how closely it follows the text, 0–1 |
| `--dry-run` | — | print the plan, synthesize nothing |
| `--check` | — | verify the engine is installed + show the device |

### Tips for a good clone
- Reference audio should be **clean** — one speaker, no music, no echo.
- ~10 seconds is plenty. More isn't better; *cleaner* is better.
- Bump `--exaggeration` for energetic delivery; lower `--cfg-weight` for a slower,
  more deliberate read.

## Requirements

- **Python 3.10+** (the engine installs into a local `.venv`).
- A GPU is optional but much faster. CPU works (`./setup.sh --cpu`), just slower.

## Development

```bash
bash tests/test.sh
```

The engine is imported **lazily**, so the whole CLI — `--help`, `--check`,
`--dry-run`, argument validation — is tested here with no model, no torch, and
no GPU. CI runs the suite plus `shellcheck`.

> The actual synthesis needs the model + (ideally) a GPU, so it can't run on a
> GPU-less CI box — that part is verified by running `./setup.sh` and a real
> `clone "..."` on your own hardware. The CLI/plumbing around it is fully tested.

## Please use this responsibly

Clone **your own voice**, or one you have explicit permission to use. Don't
impersonate real people, and don't use cloned voices to deceive. You're
responsible for what you generate.

## License

MIT — see [LICENSE](LICENSE).
