# AEIC quality evaluation

`eval.py` measures how good received images are and how many bytes they cost,
so codec changes can be compared with numbers rather than by eye. It runs the
same ONNX graphs the app downloads. Unlike the fixture scripts in the parent
directory, it needs no research checkout.

For each photo and each preprocessing variant it:

1. prepares the 512×512 codec input (the `stretch` variant mirrors the app's `_toSquareRgb`),
2. runs `aeic_entropy_side_fp32_op17.onnx` on CPU,
3. counts the exact bytes with `aeic_bytes.dart`, which calls the app's own entropy layer and rANS coder,
4. runs the decoder on `y_hat` (GPU when available),
5. restores the aspect ratio the way the receiver does and scores the result against the region that was sent.

## Setup

```bash
python3 -m venv ~/.venvs/aeic-eval   # or: uv venv ~/.venvs/aeic-eval
~/.venvs/aeic-eval/bin/pip install torch torchvision --index-url https://download.pytorch.org/whl/cu128
~/.venvs/aeic-eval/bin/pip install -r tools/aeic/eval/requirements.txt
```

You also need `dart` on PATH (`flutter pub get` already run), and the model
bundle. By default the bundle is read from `~/Documents/image_codec_models`;
use `--models` to point elsewhere. The first run downloads the LPIPS, DISTS and
CLIP weights into the torch and Hugging Face caches.

Check that the byte counter matches the reference coder:

```bash
dart run tools/aeic/eval/aeic_bytes.dart --selftest test/services/golden/e2e/*.aeicrec
```

## Running

From the repository root:

```bash
# Kodak (24 images, downloaded once)
~/.venvs/aeic-eval/bin/python -I tools/aeic/eval/eval.py \
  --download-kodak ~/aeic-data/kodak --out ~/aeic-runs/kodak-baseline \
  --variants stretch,crop,crop43,pad

# Your own photos; Kodak alone is not representative of what people send
~/.venvs/aeic-eval/bin/python -I tools/aeic/eval/eval.py \
  --images ~/aeic-data/mesh-photos --out ~/aeic-runs/mesh-baseline
```

| option | meaning |
|---|---|
| `--variants` | comma list of variants to compare (below) |
| `--rois FILE` | JSON `{image stem: [l, t, r, b]}` as fractions; adds subject-region (`roi_*`) scores and limits the run to listed images. `rois/kodak.json` has 17 Kodak subjects |
| `--display N` | long side of the receiver view that is scored (default 512; use 1024 for two-part variants) |
| `--decoder` | score a different decoder export, e.g. fp16 instead of int8 |
| `--limit N` | first N images only |
| `--cpu` | run the decoder on CPU (much slower) |

| variant | what is sent |
|---|---|
| `stretch` | the whole photo stretched to the square, as the app does |
| `crop`, `crop43`, `pad` | centre square crop; crop to at most 4:3 then stretch; letterbox on grey |
| `reroll1`..`reroll5` | the whole photo with the send sheet's "Try another version" tweaks (`kImageSendRerollTweaks`; keep the two tables in step) |
| `select`, `select_sq` | only the `--rois` box; the box grown to a square |
| `q<step>` | quantisation step `<step>` instead of 1 (e.g. `q0.7` spends more bytes) |
| `fit<bytes>` | per image, the finest step from the 16-step ladder that fits `<bytes>` (e.g. `fit157` = one packet) |
| `hd_tiles`, `hd_detail` | two encodes per photo: two overlapping halves; or the whole photo plus the `--rois` box, blended |

`q`/`fit` re-run the four context stages with the decode-side entropy graph;
at step 1 they reproduce the app's bytes exactly. Two-part byte counts include
the extra stream header such a format would need.

To add an experiment, write a function returning `Prepared` and register it in
`VARIANTS`.

## Comparing with JPEG XL and AVIF

`compare_codecs.py` sweeps AEIC over every quantisation step and fits JPEG XL
and AVIF to the same budgets (16–192 px thumbnails, best size per image, scored
after upscaling). AVIF is counted both as a real `.avif` file and as its AV1
data alone. Needs `imagecodecs` (in `requirements.txt`).

```bash
~/.venvs/aeic-eval/bin/python -I tools/aeic/eval/compare_codecs.py \
  --images ~/aeic-data/kodak --out ~/aeic-runs/rd
```

## Output

| file | contents |
|---|---|
| `report.html` | source next to each variant's reconstruction, with bytes, packets, LPIPS and CLIP; a red border marks CLIP < 0.80 |
| `results.csv` | one row per image × variant |
| `summary.json` | per-variant mean/median/min/max, packet histogram, run metadata |
| `recon/`, `ref/` | the scored images, at the receiver's aspect ratio |
| `tensors/*.aeic` | the bitstreams, exactly as the app would send them |

## Reading the metrics

| metric | better | what it catches |
|---|---|---|
| `bytes`, `data_chunks` | lower | airtime; one chunk carries up to 157 image bytes |
| `lpips`, `dists` | lower | perceptual difference; the main quality score for a generative decoder |
| `clip` | higher | whether the reconstruction shows the same *things* as the sent region; low values are the "fox came back as a sheep" failures |
| `clip_full` | higher | the same, against the whole original photo, so a crop pays for what it dropped |
| `psnr`, `ms_ssim` | higher | pixel fidelity; included for reference, but weak signals for this codec |

`1-pkt` in the console summary is the share of images that fit in a single data
chunk. Each image also gets one parity packet when recovery is on.

## Caveats

- Desktop ORT on CPU is not bit-identical to ORT on a phone, so an occasional rounding difference can change a byte count by one. The byte counter itself matches the reference coder exactly (see `--selftest`).
- The `stretch` resize approximates `dart:ui`'s `FilterQuality.medium`; it is not pixel-identical.
- CLIP and LPIPS are proxies. Look at the images flagged in `report.html` before drawing conclusions.
