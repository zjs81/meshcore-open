# Regenerating the AEIC test fixtures

The image codec's tests are pinned against data produced by the reference
implementation, not by the Dart code. That is the whole point: a Dart encoder
and a Dart decoder that agree with each other prove nothing, because they would
agree just as happily on a wrong wire format. These scripts produce the data the
Dart side is checked against.

They are committed here so `test/services/golden/` is reproducible. Nothing in
the app runs them.

To measure reconstruction quality and byte cost instead, use the
[evaluation harness](eval/README.md), which runs on the downloaded model bundle
and needs no research checkout.

| script | produces | used by |
|---|---|---|
| `export_golden.py` | `golden/aeic_cdf_ft32.bin`, `golden/vectors/*.gv` | `rans_coder_test.dart`, `entropy_tables_test.dart` |
| `record_entropy_io.py` | `golden/e2e/*.aeicrec`, `golden/e2e/manifest.json` | `image_codec_e2e_test.dart` |

## What they need

Neither script is self-contained. Both drive the real AEIC model, so they need
the research checkout that is **not** part of this repository:

- the AEIC source (`github.com/LuizScarlet/AEIC`) with the two local patches:
  pybind11 bumped to v2.13.6 (2.10.4 silently returns stride-0 arrays under
  NumPy 2), and `.contiguous()` on `z_hat` in both `compress()` and
  `decompress()` (the encoder and decoder otherwise land in different memory
  layouts, and the ~2.8e-7 drift that causes desynchronises the rANS decoder on
  roughly one image in 26, with no error raised)
- the `AEIC_SE_ft32.pkl` checkpoint
- the compiled C++ rANS extension (`src/cpp`, CMake) — the golden bitstreams are
  produced by it, which is what makes them worth comparing against
- PyTorch, onnxruntime, NumPy 2

## Preparing the research layout

The scripts import helpers that are not included in this app repository: `aeic_runner.py` and, for recording, `bitexact_encoder.py`. Obtain the matching research/export environment before running them. The app does not pin that external checkout’s revision; record its commit, checkpoint checksum, dependency versions, and patch diff alongside regenerated fixtures so others can reproduce your results.

Use this layout in the research checkout:

```text
exp/
  export_golden.py
  record_entropy_io.py
  aeic_runner.py
  bitexact_encoder.py
onnx/
  aeic_entropy_side_fp32_op17.onnx
  aeic_entropy_decode_fp32_op17.onnx
results/golden/
data/kodak_raw/
data/custom/
```

Copy the two scripts from this directory into `exp/`. Their output paths are resolved relative to the scripts’ parent directory, not just the shell’s working directory. Supply the ft32 checkpoint and expected image corpus in the research environment.

## Running them

From the prepared research checkout, with its dependencies installed:

```bash
AEIC_DEVICE=cpu python exp/export_golden.py --ckpt /absolute/path/AEIC_SE_ft32.pkl
AEIC_DEVICE=cpu python exp/record_entropy_io.py --ckpt /absolute/path/AEIC_SE_ft32.pkl --scratch /absolute/path/aeic-scratch
python exp/record_entropy_io.py --verify-only
```

The recorder’s default scratch path is machine-specific; always supply `--scratch` or `AEIC_SCRATCH`. `--decode-graph` can select an existing recording graph; `--images` selects an explicit corpus. The exporter defaults to ten images; `--all` uses the full configured corpus.

Copy the generated contents of `results/golden/` into the app’s `test/services/golden/`. Keep paired `.gv`, `.bin`, JSON metadata, recording files, and manifest together. Review generated differences and run the relevant tests:

```bash
flutter test test/services/rans_coder_test.dart test/services/entropy_tables_test.dart test/services/image_codec_e2e_test.dart
```

## When fixtures need regeneration

Regenerate when changing the reference model, entropy tables, rANS format, or recorded tensor interface. These fixtures validate the codec/entropy pipeline, **not the separate mesh chunk headers**.

Chunk framing and metadata are defined in [image_chunk_transport.dart](../../lib/services/image_chunk_transport.dart). Changes there need transport-focused test updates; a chunk-layout-only change does not automatically require new reference codec fixtures. See the [image-message guide](../../documentation/image-messages.md).
