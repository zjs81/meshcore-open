#!/usr/bin/env python3
"""Rate-distortion comparison: AEIC (as shipped and with step rate control)
against JPEG XL and AVIF at the same byte budgets.

    python -I tools/aeic/eval/compare_codecs.py --images ~/aeic-data/kodak --out ~/aeic-runs/rd

AEIC is swept over every quantisation step in STEP_LADDER (step 1.0 is the
stream the app sends today) and also fitted per image to 1 and 2 packets.
JPEG XL and AVIF are fitted per image to each byte budget: for every candidate
size the quality setting is searched to fit, the result is decoded and
upscaled to the display size, and the size with the lowest LPIPS is kept. That
choice uses the original, which the sender has, so it is a fair best case for
the conventional codecs rather than an oracle.

AVIF is counted twice. `avif` is the real .avif file, whose ftyp+meta boxes
cost about 275 bytes before any image data. `avif_av1` counts only the AV1
payload (the mdat contents), as if the receiver rebuilt the fixed container
from a template; that is AVIF's best case for a custom wire format.

Everything is scored against the source at the same display size (long side
512, the AEIC output size). Needs `imagecodecs` with JPEG XL support on top of
the eval.py requirements.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import struct
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location("aeic_eval", HERE / "eval.py")
ev = importlib.util.module_from_spec(_spec)
sys.modules["aeic_eval"] = ev  # dataclasses look their module up here
_spec.loader.exec_module(ev)  # type: ignore[union-attr]

import imagecodecs  # noqa: E402  (after eval.py, which loads torch first)
from concurrent.futures import ThreadPoolExecutor  # noqa: E402

POOL = ThreadPoolExecutor(max_workers=12)

PACKET_BUDGETS = {"1 packet": ev.CHUNK_FIRST_CAPACITY,
                  "2 packets": ev.CHUNK_FIRST_CAPACITY + ev.CHUNK_CAPACITY}
BUDGETS = [100, 157, 200, 250, 315, 400, 500, 700]
SIZES = [16, 24, 32, 40, 48, 56, 64, 80, 96, 128, 160, 192]
JXL_EFFORT = 9
AVIF_SPEED = 2
DISPLAY = ev.SIZE


def display_size(img: Image.Image, long_side: int) -> tuple[int, int]:
    s = long_side / max(img.size)
    return (max(1, round(img.width * s)), max(1, round(img.height * s)))


def mdat_payload(avif: bytes) -> int:
    """Size of the AV1 data in an .avif file (its mdat box contents)."""
    i = 0
    while i + 8 <= len(avif):
        size, kind = struct.unpack(">I4s", avif[i:i + 8])
        header = 8
        if size == 1:
            size = struct.unpack(">Q", avif[i + 8:i + 16])[0]
            header = 16
        elif size == 0:
            size = len(avif) - i
        if kind == b"mdat":
            return size - header
        i += size
    raise ValueError("no mdat box")


def _jxl(arr: np.ndarray, q: float) -> bytes:
    return imagecodecs.jpegxl_encode(arr, distance=q, effort=JXL_EFFORT)


def _avif(arr: np.ndarray, q: float) -> bytes:
    return imagecodecs.avif_encode(arr, level=int(q), speed=AVIF_SPEED)


# name -> (encode(arr, q), decode, bytes counted, q for the smallest file,
#          q for the largest, integer q?)
CODECS = {
    "jxl": (_jxl, imagecodecs.jpegxl_decode, len, 25.0, 0.05, False),
    "avif": (_avif, imagecodecs.avif_decode, len, 0, 100, True),
    "avif_av1": (_avif, imagecodecs.avif_decode, mdat_payload, 0, 100, True),
}


def codec_fit(name: str, src: Image.Image, long_side: int, budget: int) -> tuple[int, Image.Image] | None:
    """Best stream of codec `name` for `src` at `long_side` px within `budget`.

    Returns (counted bytes, decoded image), or None if even the lowest quality
    does not fit.
    """
    enc, dec, count, q_small, q_large, integer = CODECS[name]
    small = np.asarray(src.resize(display_size(src, long_side), Image.LANCZOS))
    data = enc(small, q_small)
    if count(data) > budget:
        return None
    best = data
    lo, hi = q_small, q_large  # lo always fits
    for _ in range(12):
        if integer:
            if abs(hi - lo) <= 1:
                break
            mid = (lo + hi) // 2
        else:
            mid = (lo * hi) ** 0.5  # JPEG XL distance acts roughly logarithmically
        data = enc(small, mid)
        if count(data) <= budget:
            best, lo = data, mid
        else:
            hi = mid
    decoded = Image.fromarray(np.asarray(dec(best))[..., :3], "RGB")
    return count(best), decoded


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--images", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--models", type=Path, default=ev.DEFAULT_MODELS)
    ap.add_argument("--limit", type=int)
    args = ap.parse_args()

    images = ev.find_images(args.images, args.limit)
    out: Path = args.out
    work = out / "tensors"
    (out / "img").mkdir(parents=True, exist_ok=True)
    work.mkdir(parents=True, exist_ok=True)

    import torch
    gpu = torch.cuda.is_available()
    codec = ev.Codec(args.models, args.models / ev.DECODER_GRAPH, gpu)
    metrics = ev.Metrics("cuda" if gpu else "cpu")

    # ---- AEIC: every step on the ladder, one Dart run for all byte counts.
    srcs, aeic_y = {}, {}
    files = []
    for path in images:
        stem = path.stem
        src = ev.load_source(path)
        srcs[stem] = src
        side = codec.encode_side(ev.variant_stretch(src).square)
        for step in ev.STEP_LADDER:
            t = codec.encode_with_step(side, step)
            tf = work / f"{stem}.s{step:.2f}.f32"
            ev.write_tensor_file(tf, t)
            aeic_y[(stem, step)] = t["y_hat"]
            files.append(tf)
        print(f"encoded {stem}", file=sys.stderr)
    nbytes = {k: v["bytes"] for k, v in ev.count_bytes(args.models / ev.CDF_TABLE, files).items()}
    for tf in files:
        tf.unlink()

    rows = []
    emb = {}

    def score(stem: str, shown: Image.Image) -> dict:
        src = srcs[stem]
        ref = src.resize(display_size(src, DISPLAY), Image.LANCZOS)
        if stem not in emb:
            emb[stem] = metrics.clip_embed(src)
        s = metrics.score(ref, shown.resize(ref.size, Image.BICUBIC), emb[stem])
        s.pop("clip_full")
        return s

    aeic_shown = {}
    for path in images:
        stem = path.stem
        src = srcs[stem]
        for step in ev.STEP_LADDER:
            recon = codec.decode(aeic_y[(stem, step)])
            shown = recon.resize(display_size(src, DISPLAY), Image.LANCZOS)
            aeic_shown[(stem, step)] = shown
            b = nbytes[str(work / f"{stem}.s{step:.2f}.f32")]
            rows.append({"image": stem, "codec": "aeic", "step": step, "bytes": b, **score(stem, shown)})
        print(f"scored AEIC {stem}", file=sys.stderr)

    # ---- Conventional codecs: per image and budget, the best size that fits.
    for name in CODECS:
        for path in images:
            stem = path.stem
            src = srcs[stem]
            for budget in BUDGETS:
                best = None
                # imagecodecs releases the GIL, so the size search runs in threads.
                fits = list(POOL.map(lambda ls: codec_fit(name, src, ls, budget), SIZES))
                for long_side, fit in zip(SIZES, fits):
                    if fit is None:
                        continue
                    nb, small = fit
                    shown = small.resize(display_size(src, DISPLAY), Image.BICUBIC)
                    ref = src.resize(shown.size, Image.LANCZOS)
                    lp = float(metrics.lpips(metrics._t(shown), metrics._t(ref)))
                    if best is None or lp < best[0]:
                        best = (lp, long_side, nb, shown)
                if best is None:
                    continue
                _, long_side, nb, shown = best
                rows.append({"image": stem, "codec": name, "budget": budget, "px": long_side,
                             "bytes": nb, **score(stem, shown)})
                if budget in PACKET_BUDGETS.values():
                    shown.save(out / "img" / f"{stem}.{name}{budget}.png")
            print(f"scored {name} {stem}", file=sys.stderr)

    # ---- AEIC fitted to the packet budgets, picked from the sweep.
    for stem in srcs:
        for label, budget in PACKET_BUDGETS.items():
            cands = [r for r in rows if r["codec"] == "aeic" and r["image"] == stem and r["bytes"] <= budget]
            if not cands:
                cands = [max((r for r in rows if r["codec"] == "aeic" and r["image"] == stem),
                             key=lambda r: r["step"])]
            pick = min(cands, key=lambda r: r["step"])
            rows.append({**pick, "codec": f"aeic_fit{budget}", "budget": budget})
            aeic_shown[(stem, pick["step"])].save(out / "img" / f"{stem}.aeic{budget}.png")
        aeic_shown[(stem, 1.0)].save(out / "img" / f"{stem}.aeic_today.png")
        srcs[stem].resize(display_size(srcs[stem], DISPLAY), Image.LANCZOS).save(out / "img" / f"{stem}.src.png")

    (out / "rows.json").write_text(json.dumps(rows, indent=0))

    def mean(rs, k):
        return float(np.mean([r[k] for r in rs]))

    def line(name, rs):
        return (f"{name:<22}{mean(rs, 'bytes'):>7.0f}{mean(rs, 'lpips'):>8.3f}{mean(rs, 'dists'):>8.3f}"
                f"{mean(rs, 'clip'):>7.3f}{mean(rs, 'ms_ssim'):>8.3f}{mean(rs, 'psnr'):>7.2f}")

    print(f"\n{'':<22}{'bytes':>7}{'lpips':>8}{'dists':>8}{'clip':>7}{'msssim':>8}{'psnr':>7}")
    print(line("AEIC today (step 1)", [r for r in rows if r["codec"] == "aeic" and r["step"] == 1.0]))
    for label, budget in PACKET_BUDGETS.items():
        print(f"-- {label} ({budget} B)")
        print(line("  AEIC step-fit", [r for r in rows if r["codec"] == f"aeic_fit{budget}"]))
        for name in CODECS:
            rs = [r for r in rows if r["codec"] == name and r["budget"] == budget]
            print(line(f"  {name} ({len(rs)} img)", rs) if rs else f"  {name}: does not fit")
    print("\nAEIC curve")
    for step in ev.STEP_LADDER:
        print(line(f"  step {step:.2f}", [r for r in rows if r["codec"] == "aeic" and r["step"] == step]))
    for name in CODECS:
        print(f"{name} curve")
        for budget in BUDGETS:
            rs = [r for r in rows if r["codec"] == name and r["budget"] == budget]
            if rs:
                print(line(f"  <= {budget} B ({len(rs)} img)", rs))


if __name__ == "__main__":
    main()
