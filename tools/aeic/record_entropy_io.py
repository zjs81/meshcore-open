"""E2 -- record ONNX entropy tensors so the Dart four-stage loop can be tested
end to end inside `flutter test`, where the flutter_onnxruntime platform channel
does not exist.

lib/services/image_codec_entropy.dart defines an abstract `AeicEntropyNetwork`
seam with exactly three entry points:

    runEncodeSide(image)      -> z_q, yq0..3, sc0..3
    runHyperSynthesis(z_q)    -> base0
    runStage(stage, base)     -> means_supp, scales_supp   (UNMASKED)

A test can inject a fake that replays recorded tensors positionally and so
exercise the REAL Dart masking / build_indexes / rANS code against REAL data.
This script produces one self-describing binary per image containing every
tensor that crosses that seam, in call order, plus the exact rANS bitstream.

Container format: see CONTAINER_DOC at the bottom of this file (and the report).

Run:
    .venv/bin/python exp/record_entropy_io.py
    .venv/bin/python exp/record_entropy_io.py --verify-only   # re-check on disk
"""
import argparse
import hashlib
import json
import math
import os
import struct
import sys
from pathlib import Path

os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")
os.environ.setdefault("AEIC_DEVICE", "cpu")

import numpy as np
import torch
import torch.nn as nn

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(HERE))

import aeic_runner as R  # noqa: E402
from bitexact_encoder import EntropySide, build_stream  # noqa: E402

SCRATCH = Path(os.environ.get(
    "AEIC_SCRATCH",
    "/private/tmp/claude-502/-Users-Zach-Documents-mycode-aic/"
    "2e06b1a7-5277-4c57-95e0-74b34e166761/scratchpad"))

OUT_DIR = ROOT / "results" / "golden" / "e2e"
ENC_GRAPH = ROOT / "onnx" / "aeic_entropy_side_fp32_op17.onnx"
# The shipped decode-side graph (task E1). Used when present; otherwise the
# recorder exports its own equivalent scratch graph so it can still run.
SHIPPED_DECODE = ROOT / "onnx" / "aeic_entropy_decode_fp32_op17.onnx"

MAGIC = b"AEICREC1"
VERSION = 1
HEADER_BYTES = 32
ALIGN = 8

ENC_NAMES = [
    "y", "z", "z_q", "base0", "means_all", "scales_all", "y_hat",
    "yq0", "yq1", "yq2", "yq3", "sc0", "sc1", "sc2", "sc3",
]

DTYPES = {
    np.dtype("float32"): "f32",
    np.dtype("int32"): "i32",
    np.dtype("int16"): "i16",
    np.dtype("uint8"): "u8",
}


# --------------------------------------------------------------------------
# container writer / reader
# --------------------------------------------------------------------------
class Recording:
    """Ordered name -> ndarray map with a JSON index, written little-endian."""

    def __init__(self, meta=None):
        self.arrays = {}
        self.order = []
        self.meta = dict(meta or {})
        self.calls = []

    def put(self, name, arr):
        arr = np.ascontiguousarray(arr)
        if arr.dtype not in DTYPES:
            raise TypeError(f"{name}: unsupported dtype {arr.dtype}")
        if name in self.arrays:
            raise KeyError(f"duplicate entry {name}")
        self.arrays[name] = arr
        self.order.append(name)
        return name

    def write(self, path):
        entries, blob, off = [], [], HEADER_BYTES
        for name in self.order:
            a = self.arrays[name]
            pad = (-off) % ALIGN
            if pad:
                blob.append(b"\0" * pad)
                off += pad
            raw = a.tobytes(order="C")
            entries.append({"name": name, "dtype": DTYPES[a.dtype],
                            "shape": list(a.shape), "offset": off,
                            "length": len(raw)})
            blob.append(raw)
            off += len(raw)
        pad = (-off) % ALIGN
        if pad:
            blob.append(b"\0" * pad)
            off += pad
        index = json.dumps({"meta": self.meta, "calls": self.calls,
                            "entries": entries}, separators=(",", ":")).encode()
        head = (MAGIC + struct.pack("<IIQII", VERSION, 0, off, len(index), 0))
        assert len(head) == HEADER_BYTES, len(head)
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "wb") as f:
            f.write(head)
            for b in blob:
                f.write(b)
            f.write(index)
        return path.stat().st_size


def _sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


NP_OF = {"f32": np.float32, "i32": np.int32, "i16": np.int16, "u8": np.uint8}


def read_recording(path):
    raw = Path(path).read_bytes()
    if raw[:8] != MAGIC:
        raise ValueError(f"{path}: bad magic {raw[:8]!r}")
    version, flags, index_off, index_len, _ = struct.unpack("<IIQII", raw[8:32])
    if version != VERSION:
        raise ValueError(f"{path}: version {version}")
    index = json.loads(raw[index_off:index_off + index_len].decode())
    out = {}
    for e in index["entries"]:
        a = np.frombuffer(raw, dtype=NP_OF[e["dtype"]], count=e["length"] //
                          np.dtype(NP_OF[e["dtype"]]).itemsize,
                          offset=e["offset"])
        out[e["name"]] = a.reshape(e["shape"])
    return index, out


# --------------------------------------------------------------------------
# decode-side graph
# --------------------------------------------------------------------------
class DecodeSideAll(nn.Module):
    """z_q -> base0, and base -> (means_supp, scales_supp) for all four stages.

    One graph, two inputs, nine outputs; the recorder asks onnxruntime for a
    SUBSET of outputs per call, which prunes the graph exactly the way the
    shipped stage-branching decode graph does. Unmasked on purpose: the Dart
    seam applies the mask itself.
    """

    def __init__(self, codec, y_h, y_w, z_offset):
        super().__init__()
        self.h_s = codec.h_s
        self.g_c = codec.g_c
        self.adapter_in = codec.adapter_in
        self.adapter_out = codec.adapter_out
        self.y_h, self.y_w = y_h, y_w
        self.register_buffer("z_offset", z_offset.clone())

    def forward(self, z_q, base):
        z_hat = (z_q + self.z_offset).contiguous()
        base0 = self.h_s(z_hat)[:, :, : self.y_h, : self.y_w]
        outs = []
        for i in range(4):
            out = self.adapter_out[i](self.g_c(self.adapter_in[i](base)))
            m, s = out.chunk(2, 1)
            outs += [m, s]
        return (base0, *outs)


DEC_OUT_NAMES = ["base0"] + [n for i in range(4)
                             for n in (f"means{i}", f"scales{i}")]


class OrtDecodeSide:
    """Runner for the scratch nine-output recording graph."""

    def __init__(self, sess, y_shape, z_shape):
        self.sess = sess
        self.zero_base = np.zeros(y_shape, dtype=np.float32)
        self.zero_zq = np.zeros(z_shape, dtype=np.float32)

    def hyper(self, z_q):
        return self.sess.run(["base0"], {"z_q": z_q, "base": self.zero_base})[0]

    def stage(self, i, base):
        m, s = self.sess.run([f"means{i}", f"scales{i}"],
                             {"z_q": self.zero_zq, "base": base})
        return m, s


class OrtShippedDecodeSide:
    """Runner for the SHIPPED decode graph (inputs z_q, base, stage; outputs
    base0, means, scales), driven exactly the way OnnxAeicEntropyNetwork drives
    it: every call passes all three inputs and fetches all three outputs,
    because flutter_onnxruntime's session.run() has no output-subset API."""

    def __init__(self, sess, y_shape, z_shape):
        self.sess = sess
        self.zero_base = np.zeros(y_shape, dtype=np.float32)
        self.zero_zq = np.zeros(z_shape, dtype=np.float32)
        self.names = [o.name for o in sess.get_outputs()]

    def _run(self, z_q, base, stage):
        out = self.sess.run(None, {
            "z_q": z_q, "base": base,
            "stage": np.asarray([stage], dtype=np.int32)})
        return dict(zip(self.names, out))

    def hyper(self, z_q):
        return self._run(z_q, self.zero_base, -1)["base0"]

    def stage(self, i, base):
        o = self._run(self.zero_zq, base, i)
        return o["means"], o["scales"]


# --------------------------------------------------------------------------
# the arithmetic the Dart loop mirrors (kept in numpy/torch, verbatim)
# --------------------------------------------------------------------------
def sequeeze(t):
    a, b, c, d = np.split(t, 4, axis=1)
    return (a + b) + (c + d)


def unsequeeze_with_mask(sq, mask):
    parts = np.split(mask, 4, axis=1)
    return np.concatenate([sq * p for p in parts], axis=1)


def build_indexes(codec, scales_np):
    s = torch.from_numpy(np.ascontiguousarray(scales_np))
    return codec.my_build_indexes(s).numpy()


def decode_loop(codec, dec, masks_np, coder, z_indexes_t, z_shape,
                record=None):
    """codec.decompress(), driven through `dec` and recording every call."""
    z_sym = coder.decode_stream(z_indexes_t, codec.z_cdf_group_index)
    z_q = z_sym.numpy().reshape(z_shape).astype(np.float32)

    base = dec.hyper(z_q)
    if record is not None:
        record(0, "hyper_synthesis", -1,
               {"z_q": z_q, "stage": np.asarray([-1], dtype=np.int32)},
               {"base0": base})

    y_parts = []
    for i in range(4):
        mask = masks_np[i]
        m_supp, s_supp = dec.stage(i, base)
        if record is not None:
            record(1 + i, "stage", i,
                   {"base": base, "stage": np.asarray([i], dtype=np.int32)},
                   {"means": m_supp, "scales": s_supp})
        means, scales = m_supp * mask, s_supp * mask
        sq_scales = sequeeze(scales)
        idx = build_indexes(codec, sq_scales)
        sym = coder.decode_stream(torch.from_numpy(idx).reshape(-1),
                                  codec.y_cdf_group_index)
        sym = sym.numpy().astype(np.float32).reshape(sq_scales.shape)
        latent = unsequeeze_with_mask(sym + sequeeze(means), mask)
        y_parts.append(latent)
        if i < 3:
            base = base * (1 - mask) + latent
    y_hat = base * (1 - masks_np[3]) + y_parts[3]
    return y_hat


# --------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ckpt", default="AEIC_SE_ft32.pkl")
    ap.add_argument("--size", type=int, default=512)
    ap.add_argument("--images", nargs="*", default=None)
    ap.add_argument("--decode-graph", default=None,
                    help="reuse an existing decode-side graph instead of "
                         "exporting the scratch recording graph")
    ap.add_argument("--scratch", default=str(SCRATCH))
    ap.add_argument("--verify-only", action="store_true")
    args = ap.parse_args()

    if args.verify_only:
        return verify_only()

    import onnxruntime as ort

    images = args.images or [
        str(ROOT / "data" / "kodak_raw" / "kodim01.png"),
        str(ROOT / "data" / "kodak_raw" / "kodim02.png"),
        str(ROOT / "data" / "kodak_raw" / "kodim05.png"),
        str(ROOT / "data" / "custom" / "image2.webp"),
        str(ROOT / "data" / "custom" / "images.jpeg"),
    ]

    net, _ = R.load_model(ckpt=args.ckpt)
    codec = net.codec
    print("codec.update(force=True) ->", codec.update(force=True))

    y_h = y_w = args.size // 32
    z_h = z_w = math.ceil(y_h / 4)
    z_shape = (1, codec.y_channel // 2, z_h, z_w)
    y_shape = (1, codec.y_channel, y_h, y_w)
    z_indexes, z_offset = codec.entropy_bottleneck.get_compress_info(list(z_shape))

    masks = codec.get_mask_four_parts(1, codec.y_channel, y_h, y_w, device="cpu")
    masks_np = [m.numpy().astype(np.float32) for m in masks]

    # --- sessions -------------------------------------------------------
    so = ort.SessionOptions()
    so.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
    enc_sess = ort.InferenceSession(str(ENC_GRAPH), so,
                                    providers=["CPUExecutionProvider"])
    enc_names = [o.name for o in enc_sess.get_outputs()]
    print(f"encode graph {ENC_GRAPH.name} outputs: {enc_names}")

    scratch = Path(args.scratch)
    scratch.mkdir(parents=True, exist_ok=True)
    if args.decode_graph:
        dec_path = Path(args.decode_graph)
    elif SHIPPED_DECODE.exists():
        dec_path = SHIPPED_DECODE
    else:
        dec_path = scratch / "aeic_entropy_decode_record_fp32.onnx"
    if not dec_path.exists():
        print(f"exporting decode-side recording graph -> {dec_path}")
        mod = DecodeSideAll(codec, y_h, y_w, z_offset).eval()
        with torch.no_grad():
            torch.onnx.export(
                mod,
                (torch.zeros(z_shape), torch.zeros(y_shape)),
                str(dec_path),
                input_names=["z_q", "base"], output_names=DEC_OUT_NAMES,
                opset_version=17, do_constant_folding=True, dynamo=False)
    print(f"  decode graph {dec_path.name} "
          f"{dec_path.stat().st_size / 2**20:.1f} MB")
    dec_sess = ort.InferenceSession(str(dec_path), so,
                                    providers=["CPUExecutionProvider"])
    dec_inputs = [i.name for i in dec_sess.get_inputs()]
    dec_outputs = [o.name for o in dec_sess.get_outputs()]
    print(f"  decode graph inputs {dec_inputs} outputs {dec_outputs}")
    if "stage" in dec_inputs:
        dec = OrtShippedDecodeSide(dec_sess, y_shape, z_shape)
    else:
        dec = OrtDecodeSide(dec_sess, y_shape, z_shape)

    # PyTorch reference module, only to prove the ONNX encode graph still
    # matches torch on these images (cheap, and it catches a stale graph).
    ref = EntropySide(codec, y_h, y_w, z_offset).eval()

    golden_dir = ROOT / "results" / "golden" / "vectors"
    written = []
    for path in images:
        stem = Path(path).stem
        x = R.load_image(path, size=args.size)
        xnp = x.cpu().numpy()

        enc = dict(zip(enc_names, enc_sess.run(None, {"image": xnp})))
        with torch.no_grad():
            t_out = ref(x)
        tref = {n: v.cpu().numpy() for n, v in zip(ENC_NAMES, t_out)}
        # Only the INTEGERS have to match torch: ~99% of the float tensors
        # differ between runtimes and that is fine (see results/bitexact_encoder.md).
        # For the scales, the integer that matters is my_build_indexes(scales).
        torch_match = (
            np.array_equal(enc["z_q"], tref["z_q"])
            and all(np.array_equal(enc[f"yq{i}"], tref[f"yq{i}"]) for i in range(4))
            and all(np.array_equal(
                build_indexes(codec, sequeeze(enc[f"sc{i}"])),
                build_indexes(codec, sequeeze(tref[f"sc{i}"]))) for i in range(4)))

        stream, sym, idx = build_stream(
            codec, enc["z_q"].reshape(-1).copy(), z_indexes,
            [torch.from_numpy(enc[f"yq{i}"]) for i in range(4)],
            [torch.from_numpy(enc[f"sc{i}"]) for i in range(4)])

        golden = golden_dir / f"{stem}.bin"
        golden_match = None
        if golden.exists():
            golden_match = (golden.read_bytes() == stream)

        # --- decode replay, recording every seam call -------------------
        rec = Recording(meta={
            "format": "aeic-entropy-e2e-recording",
            "version": VERSION,
            "image": Path(path).name,
            "stem": stem,
            "checkpoint": args.ckpt,
            "size": args.size,
            "y_shape": list(y_shape),
            "z_shape": list(z_shape),
            "squeezed_shape": [1, codec.y_channel // 4, y_h, y_w],
            "encode_graph": ENC_GRAPH.name,
            "encode_graph_sha256": _sha(ENC_GRAPH),
            "decode_graph": dec_path.name,
            "decode_graph_sha256": _sha(dec_path),
            "z_cdf_group": int(codec.z_cdf_group_index),
            "y_cdf_group": int(codec.y_cdf_group_index),
            "cdf_table": "aeic_cdf_ft32.bin",
            "byte_order": "little",
        })
        for n in ENC_NAMES:
            rec.put(f"enc/{n}", enc[n])
        rec.put("enc/bitstream", np.frombuffer(stream, dtype=np.uint8))
        rec.put("enc/z_indexes", z_indexes.reshape(-1).numpy().astype(np.int16))
        rec.put("enc/z_symbols",
                np.asarray(enc["z_q"], dtype=np.int16).reshape(-1))
        for i in range(4):
            rec.put(f"enc/symbols{i}", np.asarray(sym[i], dtype=np.int16))
            rec.put(f"enc/indexes{i}", np.asarray(idx[i], dtype=np.int16))

        def record(k, kind, stage, ins, outs):
            e = {"index": k, "kind": kind, "stage": stage,
                 "inputs": {}, "outputs": {}}
            for kk, v in ins.items():
                e["inputs"][kk] = rec.put(f"dec/call{k}/in/{kk}", np.asarray(v))
            for kk, v in outs.items():
                e["outputs"][kk] = rec.put(f"dec/call{k}/out/{kk}",
                                           np.asarray(v, dtype=np.float32))
            rec.calls.append(e)

        codec.entropy_coder.set_stream(stream)
        y_hat_dec = decode_loop(codec, dec, masks_np, codec.entropy_coder,
                                z_indexes.reshape(-1), z_shape, record=record)
        rec.put("dec/y_hat", y_hat_dec.astype(np.float32))
        rec.meta["bitstream_bytes"] = len(stream)
        rec.meta["bitstream_sha256"] = hashlib.sha256(stream).hexdigest()
        rec.meta["encode_graph_matches_torch_symbols"] = bool(torch_match)
        rec.meta["golden_vector_match"] = golden_match
        rec.meta["decoded_y_hat_equals_encoder_y_hat"] = bool(
            np.array_equal(y_hat_dec, enc["y_hat"]))
        rec.meta["decoded_y_hat_max_abs_diff"] = float(
            np.abs(y_hat_dec.astype(np.float64)
                   - enc["y_hat"].astype(np.float64)).max())

        dst = OUT_DIR / f"{stem}.aeicrec"
        nbytes = rec.write(dst)
        written.append(dst)
        print(f"  {stem:<10} stream={len(stream)}B golden={golden_match} "
              f"torch_sym={torch_match} "
              f"y_hat_exact={rec.meta['decoded_y_hat_equals_encoder_y_hat']} "
              f"(max {rec.meta['decoded_y_hat_max_abs_diff']:.3g}) "
              f"-> {dst.name} {nbytes/2**20:.2f} MB", flush=True)

    # index file so a Dart test can enumerate fixtures without a directory scan
    manifest = {"format": "aeic-entropy-e2e-recording", "version": VERSION,
                "checkpoint": args.ckpt, "size": args.size,
                "files": [{"file": p.name,
                           "bytes": p.stat().st_size,
                           "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
                          for p in written]}
    (OUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=1))
    print(f"wrote {OUT_DIR}/manifest.json")

    print("\n=== verifying recordings from disk ===")
    verify_only()


def verify_only():
    """Reload every recording and prove it round-trips through the C++ coder."""
    net, _ = R.load_model(ckpt="AEIC_SE_ft32.pkl")
    codec = net.codec
    codec.update(force=True)
    ok_all = True
    for path in sorted(OUT_DIR.glob("*.aeicrec")):
        index, t = read_recording(path)
        meta = index["meta"]
        stream = t["enc/bitstream"].tobytes()

        # 1) recorded encode tensors -> bitstream
        s2, sym2, idx2 = build_stream(
            codec, t["enc/z_q"].reshape(-1).astype(np.float32).copy(),
            torch.from_numpy(t["enc/z_indexes"].astype(np.int32)).reshape(
                meta["z_shape"]),
            [torch.from_numpy(t[f"enc/yq{i}"].copy()) for i in range(4)],
            [torch.from_numpy(t[f"enc/sc{i}"].copy()) for i in range(4)])
        enc_ok = (s2 == stream)
        sym_ok = all(np.array_equal(np.asarray(sym2[i], dtype=np.int16),
                                    t[f"enc/symbols{i}"]) for i in range(4))
        idx_ok = all(np.array_equal(np.asarray(idx2[i], dtype=np.int16),
                                    t[f"enc/indexes{i}"]) for i in range(4))

        # 2) recorded decode tensors -> same symbols, same y_hat
        masks = codec.get_mask_four_parts(1, codec.y_channel,
                                          meta["y_shape"][2], meta["y_shape"][3],
                                          device="cpu")
        masks_np = [m.numpy().astype(np.float32) for m in masks]
        calls = index["calls"]

        class Replay:
            def hyper(self, z_q):
                assert np.array_equal(z_q, t[calls[0]["inputs"]["z_q"]])
                return t[calls[0]["outputs"]["base0"]]

            def stage(self, i, base):
                c = calls[1 + i]
                assert np.array_equal(base, t[c["inputs"]["base"]]), \
                    f"{path.name}: stage {i} base input drifted"
                return t[c["outputs"]["means"]], t[c["outputs"]["scales"]]

        codec.entropy_coder.set_stream(stream)
        y_hat = decode_loop(
            codec, Replay(), masks_np, codec.entropy_coder,
            torch.from_numpy(t["enc/z_indexes"].astype(np.int32)),
            tuple(meta["z_shape"]))
        dec_ok = np.array_equal(y_hat, t["dec/y_hat"])

        ok = enc_ok and sym_ok and idx_ok and dec_ok
        ok_all &= ok
        print(f"  {path.name:<22} {path.stat().st_size/2**20:5.2f} MB "
              f"encode->bitstream={enc_ok} symbols={sym_ok} indexes={idx_ok} "
              f"decode_replay_y_hat={dec_ok} "
              f"golden={meta.get('golden_vector_match')} {'OK' if ok else 'FAIL'}")
    print("ALL RECORDINGS VERIFIED" if ok_all else "VERIFICATION FAILED")
    return 0 if ok_all else 1


CONTAINER_DOC = """
.aeicrec container (little-endian throughout)

  0   8    magic  b"AEICREC1"
  8   4    uint32 version = 1
  12  4    uint32 flags = 0
  16  8    uint64 index_offset   (byte offset of the JSON index)
  24  4    uint32 index_length   (bytes of the JSON index)
  28  4    uint32 reserved = 0
  32  ..   tensor blob, every tensor 8-byte aligned, C order
  index_offset .. +index_length   UTF-8 JSON index

JSON index:
  {"meta": {...}, "calls": [...], "entries":
     [{"name":..., "dtype":"f32"|"i32"|"i16"|"u8", "shape":[...],
       "offset":<abs byte offset>, "length":<bytes>}, ...]}

Dart: read the 32-byte header, jsonDecode the index, then for f32 entries use
ByteData/Float32List.view(buffer, offset, length ~/ 4) -- offsets are 8-byte
aligned so the typed-data views are always legal.
"""

if __name__ == "__main__":
    sys.exit(main() or 0)
