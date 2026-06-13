#!/usr/bin/env python3
"""clone — make anything say anything, in any voice, on your own GPU.

Zero-shot voice cloning with Chatterbox (Resemble AI, MIT). Give it ~5-15s of
clean reference audio and some text; it speaks the text in that voice. No
account, no per-character fees, runs locally.

    clone "hey, welcome back to the channel" --voice me.wav
    clone "subscribe for more" --voice me.wav --out intro.wav
    clone "no reference? you still get a clean default voice"

The model loads lazily, so --check / --dry-run / --help work without it
installed (run ./setup.sh once to install the engine + pull the model).
"""
from __future__ import annotations

import argparse
import os
import sys

DEFAULT_OUT = "clone-out.wav"


def pick_device(requested: str = "auto") -> str:
    if requested != "auto":
        return requested
    try:
        import torch  # noqa: PLC0415 - optional, probed at runtime
        if torch.cuda.is_available():
            return "cuda"
        if getattr(torch.backends, "mps", None) and torch.backends.mps.is_available():
            return "mps"
    except Exception:  # noqa: BLE001
        pass
    return "cpu"


def cmd_check() -> int:
    ok = True
    for mod in ("torch", "torchaudio", "chatterbox"):
        try:
            __import__(mod)
            print(f"✓ {mod} importable")
        except Exception as e:  # noqa: BLE001
            print(f"✗ {mod} not installed ({e.__class__.__name__}) — run ./setup.sh")
            ok = False
    if ok:
        print(f"✓ device: {pick_device()}")
    return 0 if ok else 1


def synthesize(text: str, *, voice: str | None, out: str, device: str,
               exaggeration: float, cfg_weight: float) -> str:
    """Load Chatterbox and synthesize. Imported lazily so the CLI works
    (check/dry-run/help) even when the engine isn't installed yet."""
    import torchaudio  # noqa: PLC0415
    from chatterbox.tts import ChatterboxTTS  # noqa: PLC0415

    model = ChatterboxTTS.from_pretrained(device=device)
    kwargs = {"exaggeration": exaggeration, "cfg_weight": cfg_weight}
    if voice:
        kwargs["audio_prompt_path"] = voice
    wav = model.generate(text, **kwargs)
    torchaudio.save(out, wav, model.sr)
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="local zero-shot voice cloning (Chatterbox)")
    ap.add_argument("text", nargs="?", help="what to say")
    ap.add_argument("--voice", help="reference audio (wav/mp3, ~5-15s clean speech)")
    ap.add_argument("--out", default=DEFAULT_OUT, help=f"output wav (default {DEFAULT_OUT})")
    ap.add_argument("--device", default="auto", choices=["auto", "cuda", "mps", "cpu"])
    ap.add_argument("--exaggeration", type=float, default=0.5,
                    help="expressiveness 0-1 (default 0.5)")
    ap.add_argument("--cfg-weight", type=float, default=0.5,
                    help="pacing/adherence 0-1 (default 0.5)")
    ap.add_argument("--dry-run", action="store_true",
                    help="print the plan, synthesize nothing (no model needed)")
    ap.add_argument("--check", action="store_true", help="verify the engine is installed")
    args = ap.parse_args()

    if args.check:
        return cmd_check()
    if not args.text:
        ap.error("give me some text to say (or use --check)")

    device = pick_device(args.device)
    if args.dry_run:
        print("clone plan:")
        print(f"  text:         {args.text!r}")
        print(f"  voice:        {args.voice or '(default voice — no cloning)'}")
        print(f"  out:          {args.out}")
        print(f"  device:       {device}")
        print(f"  exaggeration: {args.exaggeration}")
        print(f"  cfg_weight:   {args.cfg_weight}")
        return 0

    if args.voice and not os.path.isfile(args.voice):
        print(f"✗ no such reference audio: {args.voice}", file=sys.stderr)
        return 1

    print(f'cloning -> "{args.text}"  [voice: {args.voice or "default"}, {device}]')
    try:
        out = synthesize(args.text, voice=args.voice, out=args.out, device=device,
                         exaggeration=args.exaggeration, cfg_weight=args.cfg_weight)
    except ImportError:
        print("✗ engine not installed. Run ./setup.sh first.", file=sys.stderr)
        return 1
    print(f"✓ saved {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
