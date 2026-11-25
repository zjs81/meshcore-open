#!/usr/bin/env python3
"""Quality/rate evaluation harness for the AEIC image codec.

Runs a folder of photos through the same three ONNX graphs the app ships,
counts the exact bytes with the app's own Dart rANS coder (aeic_bytes.dart),
and scores what the receiver would see.

    python -I tools/aeic/eval/eval.py --images ~/photos --out /tmp/aeic-eval

See README.md in this directory for setup and how to read the output.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import hashlib
import html
import json
import math
import os
import shutil
import subprocess
import sys
import time
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

import numpy as np
from PIL import Image, ImageOps

# torch must be imported before onnxruntime so the CUDA libraries that ship in
# the torch wheels are already loaded when ORT's CUDA provider looks for them.
import torch  # noqa: E402  (import order is deliberate)
import onnxruntime as ort  # noqa: E402

SIZE = 512
REPO = Path(__file__).resolve().parents[3]
DART_TOOL = Path(__file__).resolve().parent / "aeic_bytes.dart"
DEFAULT_MODELS = Path.home() / "Documents" / "image_codec_models"
SIDE_GRAPH = "aeic_entropy_side_fp32_op17.onnx"
DECODER_GRAPH = "aeic_decoder_qdq_conv_pct.onnx"
CDF_TABLE = "aeic_cdf_ft32.bin"
CONTEXT_GRAPH = "aeic_entropy_decode_fp32_op17.onnx"


def _stage_masks() -> list[np.ndarray]:
    """The four checkerboard masks, as AeicMaskSet.isLive defines them."""
    perm = [0, 3, 2, 1]
    c = np.arange(256)[:, None, None] // 64
    yy = np.arange(16)[None, :, None]
    xx = np.arange(16)[None, None, :]
    micro = ((yy & 1) << 1) | (xx & 1)
    return [((c ^ perm[s]) == micro)[None] for s in range(4)]


STAGE_MASKS = _stage_masks()

# Quantisation steps a stream could signal in 4 bits (the metadata byte's rate
# and resolution fields). 1.0 is today's ft32 stream.
STEP_LADDER = [0.40, 0.45, 0.50, 0.55, 0.60, 0.66, 0.72, 0.79,
               0.86, 0.93, 1.00, 1.10, 1.20, 1.32, 1.45, 1.60]
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tif", ".tiff"}

# Mirrors lib/services/image_chunk_transport.dart. aeic_bytes.dart reports the
# authoritative count; these are only used for the summary's packet totals.
PARITY_CHUNKS = 1


# --------------------------------------------------------------------------
# Preprocessing variants
# --------------------------------------------------------------------------
#
# A variant turns the (EXIF-rotated) source photo into the 512x512 codec input
# and says which part of the source it represents, so the reconstruction can
# be compared with that region at its true aspect ratio, which is what the
# receiver displays.


@dataclass
class Prepared:
    square: Image.Image  # 512x512 RGB, what the encoder sees
    region: tuple[int, int, int, int]  # source box (l, t, r, b) it represents
    content_box: tuple[int, int, int, int]  # box inside `square` holding it
    # For multi-part variants: width in source pixels of the cross-fade along
    # this part's edges that lie inside the picture (not on its border).
    feather: int = 0


def _resize(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    # The app draws with dart:ui FilterQuality.medium: bilinear sampling over
    # mipmaps. A box pre-reduce followed by bilinear is the closest PIL match.
    return img.resize(size, Image.BILINEAR, reducing_gap=2.0)


def _full(img: Image.Image) -> tuple[int, int, int, int]:
    return (0, 0, img.width, img.height)


def variant_stretch(img: Image.Image) -> Prepared:
    """What the app does today: the whole frame squeezed into the square."""
    return Prepared(_resize(img, (SIZE, SIZE)), _full(img), (0, 0, SIZE, SIZE))


def _centre_crop_box(img: Image.Image, max_ratio: float) -> tuple[int, int, int, int]:
    w, h = img.size
    ratio = w / h
    if ratio > max_ratio:
        cw = round(h * max_ratio)
        left = (w - cw) // 2
        return (left, 0, left + cw, h)
    if ratio < 1 / max_ratio:
        ch = round(w * max_ratio)
        top = (h - ch) // 2
        return (0, top, w, top + ch)
    return _full(img)


def variant_crop(img: Image.Image) -> Prepared:
    """Centre square crop: no distortion, loses the edges of the frame."""
    box = _centre_crop_box(img, 1.0)
    return Prepared(_resize(img.crop(box), (SIZE, SIZE)), box, (0, 0, SIZE, SIZE))


def variant_crop43(img: Image.Image) -> Prepared:
    """Crop to at most 4:3 (or 3:4), then stretch what is left."""
    box = _centre_crop_box(img, 4 / 3)
    return Prepared(_resize(img.crop(box), (SIZE, SIZE)), box, (0, 0, SIZE, SIZE))


def variant_pad(img: Image.Image) -> Prepared:
    """Letterbox on mid-grey: no distortion, spends latent area on the bars."""
    w, h = img.size
    scale = SIZE / max(w, h)
    nw, nh = max(1, round(w * scale)), max(1, round(h * scale))
    canvas = Image.new("RGB", (SIZE, SIZE), (128, 128, 128))
    left, top = (SIZE - nw) // 2, (SIZE - nh) // 2
    canvas.paste(_resize(img, (nw, nh)), (left, top))
    return Prepared(canvas, _full(img), (left, top, left + nw, top + nh))


# Re-roll tweaks: (zoom, dx, dy) as fractions of the source. Mirrors
# kImageSendRerollTweaks / rerollSourceRect in
# lib/widgets/image_send_codec_binding.dart; keep the two in step.
REROLL_TWEAKS = [
    (1.0, 0.0, 0.0),
    (1.02, 0.005, 0.0),
    (1.02, -0.005, 0.005),
    (1.04, 0.0, -0.005),
    (1.03, 0.01, 0.01),
    (1.03, -0.01, -0.01),
]


def reroll_source_rect(w: int, h: int, variant: int) -> tuple[float, float, float, float]:
    """Source rect for re-roll `variant`: a near-invisible zoom and shift."""
    zoom, dx, dy = REROLL_TWEAKS[variant]
    cw, ch = w / zoom, h / zoom
    left = min(max((w - cw) / 2 + dx * w, 0.0), w - cw)
    top = min(max((h - ch) / 2 + dy * h, 0.0), h - ch)
    return (left, top, left + cw, top + ch)


def variant_reroll(img: Image.Image, variant: int) -> Prepared:
    """Whole photo with re-roll tweak `variant`, stretched like `stretch`.

    Scored against the full frame: the tweak only drops a percent or two at
    the edges, which is what the sender sees as "the whole photo".
    """
    l, t, r, b = reroll_source_rect(img.width, img.height, variant)
    # PIL's resize box takes float source coordinates, like drawImageRect.
    square = img.resize((SIZE, SIZE), Image.BILINEAR, box=(l, t, r, b), reducing_gap=2.0)
    return Prepared(square, _full(img), (0, 0, SIZE, SIZE))


VARIANTS: dict[str, Callable[[Image.Image], Prepared]] = {
    "stretch": variant_stretch,
    "crop": variant_crop,
    "crop43": variant_crop43,
    "pad": variant_pad,
    **{f"reroll{k}": (lambda img, k=k: variant_reroll(img, k)) for k in range(1, len(REROLL_TWEAKS))},
}

# Need a box per image (--rois), so they are not in VARIANTS.
SELECT = "select"
SELECT_SQUARE = "select_sq"
SELECT_VARIANTS = (SELECT, SELECT_SQUARE)

Box = tuple[int, int, int, int]


def roi_box(img: Image.Image, frac: list[float]) -> Box:
    """Fractional [l, t, r, b] -> pixel box in the (EXIF-rotated) source."""
    l, t, r, b = frac
    w, h = img.size
    return (round(l * w), round(t * h), round(r * w), round(b * h))


def variant_select(img: Image.Image, box: Box) -> Prepared:
    """The user's selection, stretched into the square like `stretch`.

    The aspect nibble restores the box's shape on the receiver, so this is the
    app's existing pipeline applied to a crop the user chose.
    """
    return Prepared(_resize(img.crop(box), (SIZE, SIZE)), box, (0, 0, SIZE, SIZE))


def square_box(img: Image.Image, box: Box) -> Box:
    """Grow `box` to a square around its centre, shifted to stay in the image.

    Models a selection tool locked to 1:1, so the codec never sees a stretch.
    Capped at the image's short side.
    """
    l, t, r, b = box
    side = min(max(r - l, b - t), img.width, img.height)
    cx, cy = (l + r) / 2, (t + b) / 2
    nl = int(round(min(max(cx - side / 2, 0), img.width - side)))
    nt = int(round(min(max(cy - side / 2, 0), img.height - side)))
    return (nl, nt, nl + side, nt + side)


# --------------------------------------------------------------------------
# HD: two encoded parts per photo, aimed at a two-packet budget
# --------------------------------------------------------------------------
#
# The model is fixed at 512x512 / ft32, so "HD" spends the second packet on a
# second 512x512 encode. The parts travel as one stream; the receiver decodes
# both and blends them. Overheads below are what the stream would need on top
# of the bitstreams (a hypothetical layout, not implemented in the app).

HD_TILES = "hd_tiles"
HD_DETAIL = "hd_detail"
HD_VARIANTS = (HD_TILES, HD_DETAIL)
HD_OVERHEAD = {
    HD_TILES: 1,  # length of part 0, so the receiver can split the stream
    HD_DETAIL: 1 + 4,  # that, plus the detail box quantised to 4 bytes
}
TILE_OVERLAP = 0.08  # of the long side, cross-faded at the seam


def variant_hd_tiles(img: Image.Image) -> list[Prepared]:
    """Two overlapping halves along the long side, each encoded at 512x512.

    Doubles the pixel count. A 3:2 photo splits into two near-square halves,
    so each half is also stretched far less than the whole frame would be.
    """
    w, h = img.size
    long_side = max(w, h)
    ov = round(long_side * TILE_OVERLAP)
    half = (long_side + ov) // 2
    if w >= h:
        boxes = [(0, 0, half, h), (w - half, 0, w, h)]
    else:
        boxes = [(0, 0, w, half), (0, h - half, w, h)]
    return [Prepared(_resize(img.crop(b), (SIZE, SIZE)), b, (0, 0, SIZE, SIZE), feather=ov)
            for b in boxes]


def variant_hd_detail(img: Image.Image, box: Box) -> list[Prepared]:
    """The whole photo, plus the selected subject blended in at higher detail."""
    detail = variant_select(img, box)
    detail.feather = max(4, round(0.08 * min(box[2] - box[0], box[3] - box[1])))
    return [variant_stretch(img), detail]


def composite(src: Image.Image, parts: list[Prepared], recons: list[Image.Image],
              long_side: int) -> tuple[Image.Image, Image.Image, Box]:
    """Reference and receiver view for a variant made of one or more parts.

    The view covers the union of the parts' regions at `long_side` pixels on
    its long edge. Parts are laid down in order; each later part fades in over
    `feather` pixels along its edges that are inside the union, so seams
    cross-fade instead of cutting hard.
    """
    region = (min(p.region[0] for p in parts), min(p.region[1] for p in parts),
              max(p.region[2] for p in parts), max(p.region[3] for p in parts))
    rw, rh = region[2] - region[0], region[3] - region[1]
    s = long_side / max(rw, rh)
    size = (max(1, round(rw * s)), max(1, round(rh * s)))
    ref = src.crop(region).resize(size, Image.LANCZOS)
    canvas = np.zeros((size[1], size[0], 3), dtype=np.float64)
    for i, (p, recon) in enumerate(zip(parts, recons)):
        l, t, r, b = p.region
        x0, y0 = round((l - region[0]) * s), round((t - region[1]) * s)
        x1, y1 = round((r - region[0]) * s), round((b - region[1]) * s)
        tile = np.asarray(recon.crop(p.content_box).resize((x1 - x0, y1 - y0), Image.LANCZOS),
                          dtype=np.float64)
        alpha = np.ones((y1 - y0, x1 - x0), dtype=np.float64)
        f = min(round(p.feather * s), alpha.shape[0], alpha.shape[1])
        if i > 0 and f > 0:
            ramp = np.arange(1, f + 1, dtype=np.float64) / f
            if l > region[0]:
                alpha[:, :f] *= ramp[None, :]
            if r < region[2]:
                alpha[:, -f:] *= ramp[::-1][None, :]
            if t > region[1]:
                alpha[:f, :] *= ramp[:, None]
            if b < region[3]:
                alpha[-f:, :] *= ramp[::-1][:, None]
        a = alpha[..., None]
        canvas[y0:y1, x0:x1] = canvas[y0:y1, x0:x1] * (1 - a) + tile * a
    shown = Image.fromarray(np.clip(np.rint(canvas), 0, 255).astype(np.uint8), "RGB")
    return ref, shown, region


# Mirrors imageDataChunkCount() in image_chunk_transport.dart.
CHUNK_FIRST_CAPACITY = 157
CHUNK_CAPACITY = 158


def parse_rate_variant(v: str) -> dict | None:
    """`q0.7` -> fixed step 0.7; `fit315` -> per-image step to fit 315 bytes."""
    try:
        if v.startswith("q"):
            return {"steps": [float(v[1:])], "budget": None}
        if v.startswith("fit"):
            return {"steps": STEP_LADDER, "budget": int(v[3:])}
    except ValueError:
        return None
    return None


def data_chunks(payload_bytes: int) -> int:
    n = max(payload_bytes, 0)
    if n <= CHUNK_FIRST_CAPACITY:
        return 1
    return 1 + math.ceil((n - CHUNK_FIRST_CAPACITY) / CHUNK_CAPACITY)


# --------------------------------------------------------------------------
# Codec
# --------------------------------------------------------------------------


class Codec:
    def __init__(self, models: Path, decoder: Path, gpu: bool) -> None:
        cpu = ["CPUExecutionProvider"]
        cuda = ["CUDAExecutionProvider", "CPUExecutionProvider"] if gpu else cpu
        # The entropy graph stays on CPU: its rounded outputs decide the bytes,
        # and CPU fp32 is the closest stand-in for the phone. It costs ~0.1 s.
        self.side = ort.InferenceSession(str(models / SIDE_GRAPH), providers=cpu)
        self.context = ort.InferenceSession(str(models / CONTEXT_GRAPH), providers=cpu)
        self.decoder = ort.InferenceSession(str(decoder), providers=cuda)
        self.decoder_provider = self.decoder.get_providers()[0]

    def encode_side(self, square: Image.Image) -> dict[str, np.ndarray]:
        rgb = np.asarray(square, dtype=np.uint8)
        # Same float32 steps as aeicRgbToChw in image_codec_entropy.dart.
        chw = rgb.transpose(2, 0, 1).astype(np.float32) / np.float32(255.0)
        chw = (chw - np.float32(0.5)) * np.float32(2.0)
        names = (["z_q", "y_hat", "y", "base0"]
                 + [f"yq{i}" for i in range(4)] + [f"sc{i}" for i in range(4)])
        out = self.side.run(names, {"image": chw[None]})
        return dict(zip(names, out))

    def encode_with_step(self, side: dict[str, np.ndarray], step: float) -> dict[str, np.ndarray]:
        """Re-quantise y with step `step` instead of 1 (rate control).

        Replays the four-stage context loop the receiver runs
        (AeicEntropyCodec.decodeToLatent) with the decode-side graph, coding
        round((y - mean) / step) against scale / step. The receiver's
        reconstruction becomes symbol * step + mean. step < 1 spends more
        bytes, step > 1 fewer. At step == 1 this reproduces the side graph's
        symbols, which the harness's q1 check relies on.
        """
        st = np.float32(step)
        y, z_q = side["y"], side["z_q"]
        base = side["base0"].copy()
        out: dict[str, np.ndarray] = {"z_q": z_q}
        for stage in range(4):
            means, scales = self.context.run(
                ["means", "scales"],
                {"z_q": z_q, "base": base, "stage": np.array([stage], dtype=np.int32)})
            m = STAGE_MASKS[stage]
            sym = np.where(m, np.rint((y - means) / st), np.float32(0)).astype(np.float32)
            base = np.where(m, sym * st + means, base).astype(np.float32)
            out[f"yq{stage}"] = sym
            out[f"sc{stage}"] = np.where(m, scales / st, np.float32(0)).astype(np.float32)
        out["y_hat"] = base
        return out

    def decode(self, y_hat: np.ndarray) -> Image.Image:
        (out,) = self.decoder.run(["image"], {"y_hat": y_hat.astype(np.float32)})
        # Same mapping as _chwFloatsToRgb in image_codec_backend.dart: clamp,
        # then round half away from zero (Dart's double.round()).
        scaled = (out[0].astype(np.float64) + 1.0) * 127.5
        rgb = np.floor(np.clip(scaled, 0, 255) + 0.5).astype(np.uint8)
        return Image.fromarray(rgb.transpose(1, 2, 0), "RGB")


def write_tensor_file(path: Path, t: dict[str, np.ndarray]) -> None:
    parts = [t["z_q"]] + [t[f"yq{i}"] for i in range(4)] + [t[f"sc{i}"] for i in range(4)]
    with open(path, "wb") as f:
        for p in parts:
            f.write(np.ascontiguousarray(p, dtype="<f4").tobytes())


def count_bytes(cdf: Path, tensor_files: list[Path]) -> dict[str, dict]:
    if not tensor_files:
        return {}
    dart = shutil.which("dart")
    if dart is None:
        sys.exit("dart is not on PATH; it is needed to run aeic_bytes.dart")
    cmd = [dart, "run", str(DART_TOOL), str(cdf), *map(str, tensor_files)]
    proc = subprocess.run(cmd, cwd=REPO, capture_output=True, text=True)
    if proc.returncode != 0:
        sys.exit(f"aeic_bytes.dart failed:\n{proc.stderr}")
    results = {}
    for line in proc.stdout.splitlines():
        line = line.strip()
        if line.startswith("{"):
            row = json.loads(line)
            results[row["file"]] = row
    return results


# --------------------------------------------------------------------------
# Metrics
# --------------------------------------------------------------------------


class Metrics:
    """Full-reference scores. Higher is better except LPIPS and DISTS."""

    def __init__(self, device: str) -> None:
        import open_clip
        import piq

        self.piq = piq
        self.device = device
        self.lpips = piq.LPIPS(reduction="none").to(device).eval()
        self.dists = piq.DISTS(reduction="none").to(device).eval()
        model, _, preprocess = open_clip.create_model_and_transforms(
            "ViT-B-32", pretrained="laion2b_s34b_b79k"
        )
        self.clip = model.to(device).eval()
        self.clip_pre = preprocess

    def _t(self, img: Image.Image) -> torch.Tensor:
        a = np.asarray(img, dtype=np.float32) / 255.0
        return torch.from_numpy(a).permute(2, 0, 1)[None].to(self.device)

    @torch.no_grad()
    def clip_embed(self, img: Image.Image) -> torch.Tensor:
        # CLIP's own preprocessing centre-crops to a square, which would hide
        # the frame edges -- exactly what crop variants throw away. Letterbox
        # first so the whole image is scored.
        side = max(img.size)
        boxed = Image.new("RGB", (side, side), (0, 0, 0))
        boxed.paste(img, ((side - img.width) // 2, (side - img.height) // 2))
        x = self.clip_pre(boxed)[None].to(self.device)
        e = self.clip.encode_image(x)
        return e / e.norm(dim=-1, keepdim=True)

    @torch.no_grad()
    def score(self, ref: Image.Image, out: Image.Image, full_src_emb: torch.Tensor) -> dict:
        r, o = self._t(ref), self._t(out)
        out_emb = self.clip_embed(out)
        return {
            "psnr": float(self.piq.psnr(o, r, data_range=1.0)),
            "ms_ssim": float(self.piq.multi_scale_ssim(o, r, data_range=1.0)),
            "lpips": float(self.lpips(o, r)),
            "dists": float(self.dists(o, r)),
            # Semantic agreement with exactly what was sent ...
            "clip": float((self.clip_embed(ref) * out_emb).sum()),
            # ... and with the whole original photo, so cropping is charged
            # for what it threw away.
            "clip_full": float((full_src_emb * out_emb).sum()),
        }


def roi_pair(src: Image.Image, region: Box, shown: Image.Image, box: Box) -> tuple[Image.Image, Image.Image] | None:
    """The ROI as the receiver would see it after zooming in, plus its reference.

    `shown` covers `region` of the source; the ROI is mapped into it and
    both crops are scaled to long side 512. For a full-frame variant that is an
    upscale of a few dozen pixels, which is exactly what zooming in shows.
    Returns None when the variant did not send the whole ROI.
    """
    rl, rt, rr, rb = region
    l, t, r, b = box
    if l < rl or t < rt or r > rr or b > rb:
        return None
    sx = shown.width / (rr - rl)
    sy = shown.height / (rb - rt)
    out = shown.crop((round((l - rl) * sx), round((t - rt) * sy),
                      round((r - rl) * sx), round((b - rt) * sy)))
    ref = src.crop(box)
    scale = SIZE / max(ref.size)
    size = (max(1, round(ref.width * scale)), max(1, round(ref.height * scale)))
    return ref.resize(size, Image.LANCZOS), out.resize(size, Image.BICUBIC)


# --------------------------------------------------------------------------
# Corpus
# --------------------------------------------------------------------------

KODAK_URL = "https://r0k.us/graphics/kodak/kodak/kodim{:02d}.png"


def download_kodak(dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    for i in range(1, 25):
        target = dest / f"kodim{i:02d}.png"
        if target.exists():
            continue
        print(f"downloading {target.name}", file=sys.stderr)
        tmp = target.with_suffix(".part")
        with urllib.request.urlopen(KODAK_URL.format(i), timeout=60) as r, open(tmp, "wb") as f:
            shutil.copyfileobj(r, f)
        tmp.rename(target)


def load_source(path: Path) -> Image.Image:
    img = Image.open(path)
    # Picked photos are shown upright in the app, so honour EXIF orientation.
    img = ImageOps.exif_transpose(img)
    return img.convert("RGB")


def find_images(folder: Path, limit: int | None) -> list[Path]:
    files = sorted(p for p in folder.rglob("*") if p.suffix.lower() in IMAGE_SUFFIXES)
    return files[:limit] if limit else files


# --------------------------------------------------------------------------
# Report
# --------------------------------------------------------------------------

METRIC_COLS = ["bytes", "data_chunks", "psnr", "ms_ssim", "lpips", "dists", "clip", "clip_full"]
ROI_COLS = ["roi_psnr", "roi_ms_ssim", "roi_lpips", "roi_dists", "roi_clip"]
LOWER_IS_BETTER = {"bytes", "data_chunks", "lpips", "dists", "roi_lpips", "roi_dists"}


def summarise(rows: list[dict], variants: list[str]) -> dict:
    summary = {}
    for v in variants:
        vr = [r for r in rows if r["variant"] == v]
        if not vr:
            continue
        s: dict = {"images": len(vr)}
        for m in METRIC_COLS + ROI_COLS:
            vals = np.array([r[m] for r in vr if r.get(m) not in (None, "")], dtype=np.float64)
            if vals.size == 0:
                continue
            s[m] = {"mean": float(vals.mean()), "median": float(np.median(vals)),
                    "min": float(vals.min()), "max": float(vals.max())}
        chunks = [r["data_chunks"] for r in vr]
        s["chunk_histogram"] = {str(k): chunks.count(k) for k in sorted(set(chunks))}
        s["packets_mean_with_parity"] = float(np.mean(chunks)) + PARITY_CHUNKS
        # The share of images whose CLIP agreement with the source is low.
        # This is the "fox came back as a sheep" bucket; worth eyeballing.
        s["clip_below_0.80"] = sum(1 for r in vr if r["clip"] < 0.80)
        summary[v] = s
    return summary


def print_summary(summary: dict) -> None:
    head = (f"{'variant':<10}" + "".join(f"{m:>12}" for m in METRIC_COLS)
            + f"{'1-pkt':>8}{'<=2-pkt':>9}{'clip<.8':>9}")
    print(head)
    print("-" * len(head))
    for v, s in summary.items():
        line = f"{v:<10}" + "".join(f"{s[m]['mean']:>12.4g}" for m in METRIC_COLS)
        one = s["chunk_histogram"].get("1", 0)
        two = one + s["chunk_histogram"].get("2", 0)
        line += f"{one / s['images']:>7.0%} {two / s['images']:>8.0%} {s['clip_below_0.80']:>8}"
        print(line)
    print("means; lower is better for bytes, data_chunks, lpips, dists")
    if any("roi_lpips" in s for s in summary.values()):
        print()
        print(f"{'variant':<10}" + "".join(f"{m:>13}" for m in ROI_COLS))
        for v, s in summary.items():
            if "roi_lpips" in s:
                print(f"{v:<10}" + "".join(f"{s[m]['mean']:>13.4g}" for m in ROI_COLS))
        print("scored on the selected region only, as the receiver sees it after zooming in")


def write_html(out: Path, rows: list[dict], summary: dict, meta: dict) -> None:
    def fmt(v: float, m: str) -> str:
        return f"{v:.1f}" if m in ("bytes", "data_chunks") else f"{v:.3f}"

    variants = list(summary)
    stems = list(dict.fromkeys(r["image"] for r in rows))
    by = {(r["image"], r["variant"]): r for r in rows}

    sum_rows = "".join(
        f"<tr><th>{html.escape(v)}</th>"
        + "".join(f"<td>{fmt(summary[v][m]['mean'], m)}</td>" for m in METRIC_COLS)
        + "</tr>"
        for v in variants
    )
    cards = []
    for stem in stems:
        cells = []
        first = by[(stem, variants[0])]
        cells.append(
            f'<figure><img loading="lazy" src="{html.escape(first["ref_png"])}">'
            f"<figcaption>source</figcaption></figure>"
        )
        for v in variants:
            r = by.get((stem, v))
            if not r:
                continue
            warn = " warn" if r["clip"] < 0.80 else ""
            cells.append(
                f'<figure class="{warn.strip()}"><img loading="lazy" src="{html.escape(r["out_png"])}">'
                f"<figcaption><b>{html.escape(v)}</b> {r['bytes']} B / {r['data_chunks']} pkt<br>"
                f"LPIPS {r['lpips']:.3f} · CLIP {r['clip']:.3f}</figcaption></figure>"
            )
        cards.append(f"<section><h3>{html.escape(stem)}</h3><div class=row>{''.join(cells)}</div></section>")

    doc = f"""<!doctype html><html lang=en><meta charset=utf-8>
<meta name=viewport content="width=device-width,initial-scale=1">
<title>AEIC eval</title>
<style>
:root{{color-scheme:light dark;--bg:#fff;--fg:#111;--muted:#666;--line:#ddd;--warn:#c62828}}
@media (prefers-color-scheme:dark){{:root{{--bg:#121212;--fg:#eee;--muted:#aaa;--line:#333;--warn:#ef5350}}}}
body{{background:var(--bg);color:var(--fg);font:15px/1.4 system-ui,sans-serif;margin:16px}}
table{{border-collapse:collapse;margin:8px 0 24px}}td,th{{border:1px solid var(--line);padding:4px 8px;text-align:right}}
.row{{display:flex;gap:8px;flex-wrap:wrap}}figure{{margin:0;width:256px}}
figure img{{width:256px;height:auto;display:block;border:2px solid transparent}}
figure.warn img{{border-color:var(--warn)}}figcaption{{font-size:13px;color:var(--muted)}}
code{{font-size:13px}}
</style>
<h1>AEIC eval</h1>
<p><code>{html.escape(json.dumps(meta))}</code></p>
<h2>Means</h2>
<table><tr><th></th>{''.join(f'<th>{m}</th>' for m in METRIC_COLS)}</tr>{sum_rows}</table>
<p>Images are shown at the aspect ratio the receiver restores. A red border means CLIP similarity to the sent region is below 0.80, so check it by eye.</p>
{''.join(cards)}
</html>"""
    (out / "report.html").write_text(doc, encoding="utf-8")


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--images", type=Path, help="folder of photos (searched recursively)")
    ap.add_argument("--download-kodak", type=Path, metavar="DIR",
                    help="download the 24 Kodak images to DIR and use them")
    ap.add_argument("--out", type=Path, required=True, help="output folder")
    ap.add_argument("--models", type=Path, default=DEFAULT_MODELS,
                    help=f"model bundle folder (default {DEFAULT_MODELS})")
    ap.add_argument("--decoder", type=Path, help="alternative decoder .onnx (e.g. an fp16 export)")
    ap.add_argument("--variants", default="stretch",
                    help=f"comma list from: {', '.join(VARIANTS)} (default stretch)")
    ap.add_argument("--limit", type=int, help="only the first N images")
    ap.add_argument("--cpu", action="store_true", help="run the decoder on CPU too")
    ap.add_argument("--rois", type=Path,
                    help="JSON {image stem: [l, t, r, b] fractions}; enables the select and "
                         "hd_detail variants and ROI scores, and limits the run to listed images")
    ap.add_argument("--display", type=int, default=SIZE,
                    help="long side in pixels of the receiver view that is scored (default 512; "
                         "use 1024 when comparing HD variants)")
    args = ap.parse_args()

    if args.download_kodak:
        download_kodak(args.download_kodak)
        args.images = args.images or args.download_kodak
    if not args.images:
        ap.error("give --images or --download-kodak")
    variants = [v.strip() for v in args.variants.split(",") if v.strip()]
    unknown = [v for v in variants
               if v not in VARIANTS and v not in SELECT_VARIANTS and v not in HD_VARIANTS
               and parse_rate_variant(v) is None]
    if unknown:
        ap.error(f"unknown variants: {unknown}")
    rois: dict[str, list[float]] = {}
    if args.rois:
        rois = {k: v for k, v in json.loads(args.rois.read_text()).items() if not k.startswith("_")}
    if any(v in SELECT_VARIANTS + (HD_DETAIL,) for v in variants) and not rois:
        ap.error("the select and hd_detail variants need --rois")

    images = find_images(args.images, None)
    if rois:
        images = [p for p in images if p.relative_to(args.images).with_suffix("").as_posix() in rois]
    images = images[: args.limit] if args.limit else images
    if not images:
        sys.exit(f"no images under {args.images}")

    out: Path = args.out
    work = out / "tensors"
    dirs = [work] + [out / k / v for k in ("recon", "ref", "roi") for v in variants]
    for d in dirs:
        d.mkdir(parents=True, exist_ok=True)

    decoder_path = args.decoder or (args.models / DECODER_GRAPH)
    gpu = not args.cpu and torch.cuda.is_available()
    codec = Codec(args.models, decoder_path, gpu)
    metrics = Metrics("cuda" if gpu else "cpu")
    print(f"{len(images)} images x {len(variants)} variants; decoder on {codec.decoder_provider}",
          file=sys.stderr)

    # Pass 1: preprocess + encode side, so every byte count is one Dart run.
    jobs = []
    for path in images:
        src = load_source(path)
        key = path.relative_to(args.images).with_suffix("").as_posix()
        stem = key.replace("/", "__")
        box = roi_box(src, rois[key]) if key in rois else None
        for v in variants:
            if (v in SELECT_VARIANTS or v == HD_DETAIL) and box is None:
                continue
            if v == SELECT:
                parts = [variant_select(src, box)]
            elif v == SELECT_SQUARE:
                parts = [variant_select(src, square_box(src, box))]
            elif v == HD_TILES:
                parts = variant_hd_tiles(src)
            elif v == HD_DETAIL:
                parts = variant_hd_detail(src, box)
            elif parse_rate_variant(v) is not None:
                parts = [variant_stretch(src)]
            else:
                parts = [VARIANTS[v](src)]
            rate = parse_rate_variant(v)
            steps = rate["steps"] if rate else [None]
            t0 = time.perf_counter()
            encoded = []  # per part: [(step, y_hat, tensor file), ...]
            for i, p in enumerate(parts):
                side = codec.encode_side(p.square)
                cands = []
                for step in steps:
                    tensors = side if step is None else codec.encode_with_step(side, step)
                    tag = "" if step is None else f".s{step:.2f}"
                    tf = work / f"{stem}.{v}.p{i}{tag}.f32"
                    write_tensor_file(tf, tensors)
                    cands.append((step, tensors["y_hat"], tf))
                encoded.append(cands)
            enc_s = time.perf_counter() - t0
            jobs.append((path, stem, v, src, parts, box, encoded, enc_s))
    byte_rows = count_bytes(args.models / CDF_TABLE,
                            [tf for j in jobs for cands in j[6] for _, _, tf in cands])

    # Pick one candidate per part. A fit<N> variant takes the finest step whose
    # stream fits N bytes, or the coarsest step if none does.
    for j in jobs:
        rate = parse_rate_variant(j[2])
        chosen = []
        for cands in j[6]:
            if rate and rate["budget"] is not None:
                fitting = [c for c in cands if byte_rows[str(c[2])]["bytes"] <= rate["budget"]]
                chosen.append(min(fitting, key=lambda c: c[0]) if fitting
                              else max(cands, key=lambda c: c[0]))
            else:
                chosen.append(cands[0])
        j[6][:] = chosen

    # Pass 2: decode + score.
    rows = []
    emb_cache: dict[str, torch.Tensor] = {}
    for n, (path, stem, v, src, parts, box, encoded, enc_s) in enumerate(jobs, 1):
        t0 = time.perf_counter()
        recons = [codec.decode(y_hat) for _, y_hat, _ in encoded]
        dec_s = time.perf_counter() - t0
        ref, shown, region = composite(src, parts, recons, args.display)
        part_bytes = [byte_rows[str(tf)]["bytes"] for _, _, tf in encoded]
        total_bytes = sum(part_bytes) + HD_OVERHEAD.get(v, 0)
        chunks = data_chunks(total_bytes)
        if len(parts) == 1:
            assert chunks == byte_rows[str(encoded[0][2])]["data_chunks"], "chunk mirror drifted"
        if stem not in emb_cache:
            emb_cache[stem] = metrics.clip_embed(src)
        scores = metrics.score(ref, shown, emb_cache[stem])
        roi = roi_pair(src, region, shown, box) if box else None
        if roi:
            roi_scores = metrics.score(roi[0], roi[1], emb_cache[stem])
            scores.update({f"roi_{k}": roi_scores[k] for k in ("psnr", "ms_ssim", "lpips", "dists", "clip")})
            roi[1].save(out / "roi" / v / f"{stem}.png")
            roi[0].save(out / "roi" / v / f"{stem}.ref.png")
        else:
            scores.update({c: "" for c in ROI_COLS})
        out_png = Path("recon") / v / f"{stem}.png"
        ref_png = Path("ref") / v / f"{stem}.png"
        shown.save(out / out_png)
        ref.save(out / ref_png)
        row = {
            "image": stem, "variant": v, "source": str(path),
            "width": src.width, "height": src.height,
            "bytes": total_bytes, "data_chunks": chunks,
            "part_bytes": "+".join(map(str, part_bytes)),
            "step": "+".join("1.00" if st is None else f"{st:.2f}" for st, _, _ in encoded),
            **scores,
            "encode_s": round(enc_s, 3), "decode_s": round(dec_s, 3),
            "out_png": out_png.as_posix(), "ref_png": ref_png.as_posix(),
            "bitstream": ";".join(os.path.relpath(byte_rows[str(tf)]["bitstream"], out)
                                  for _, _, tf in encoded),
        }
        rows.append(row)
        print(f"[{n}/{len(jobs)}] {stem} {v}: {row['bytes']} B, LPIPS {row['lpips']:.3f}, "
              f"CLIP {row['clip']:.3f}, decode {dec_s:.2f}s", file=sys.stderr)

    summary = summarise(rows, variants)
    meta = {
        "date": dt.datetime.now().isoformat(timespec="seconds"),
        "images": str(args.images), "count": len(images), "variants": variants,
        "decoder": decoder_path.name, "decoder_sha256": sha256(decoder_path)[:16],
        "decoder_provider": codec.decoder_provider,
        "onnxruntime": ort.__version__,
    }
    with open(out / "results.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    (out / "summary.json").write_text(json.dumps({"meta": meta, "variants": summary}, indent=1))
    write_html(out, rows, summary, meta)
    for tf in work.glob("*.f32"):  # 2 MB each; the .aeic bitstreams are kept
        tf.unlink()
    print()
    print_summary(summary)
    print(f"\nreport: {out / 'report.html'}")


if __name__ == "__main__":
    main()
