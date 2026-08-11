# Regenerating the AEIC test fixtures

The image codec's tests are pinned against data produced by the reference
implementation, not by the Dart code. That is the whole point: a Dart encoder
and a Dart decoder that agree with each other prove nothing, because they would
agree just as happily on a wrong wire format. These scripts produce the data the
Dart side is checked against.

They are committed here so `test/services/golden/` is reproducible. Nothing in
the app runs them.

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

## Running them

```bash
cd <aeic-research-checkout>
AEIC_DEVICE=cpu python export_golden.py           # tables + symbol vectors
AEIC_DEVICE=cpu python record_entropy_io.py       # ONNX I/O recordings
```

Then copy the output into `test/services/golden/`.

## If you change the wire format

Regenerate. The fixtures encode the chunk framing and the metadata byte layout,
so a format change makes them stale in a way the tests will report as a codec
bug — which is the correct behaviour, but only if you know to look here.
