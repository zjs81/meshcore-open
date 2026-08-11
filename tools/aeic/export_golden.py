"""P1 -- export the AEIC ft32 entropy tables and golden rANS vectors for the Dart port.

Produces three things under results/golden/:

  1. `aeic_cdf_ft32.bin`   -- the static entropy-coder tables (both CDF groups) in a
     compact little-endian binary container. This file SHIPS in the download bundle.
     Format documented in `results/rans_port_spec.md` (section "CDF table file").

  2. `vectors/<image>.gv`  -- the exact int16 symbol and index arrays handed to the
     C++ rANS encoder, in a compact binary container.

  3. `vectors/<image>.bin` -- the exact bitstream bytes the C++ coder produced for
     that image, plus `<image>.json` with sizes/hashes/container split.

Every bitstream is written to disk and then `os.stat(path).st_size` is asserted equal
to `len(stream)`, so byte counts are auditable by stat rather than by a Python int.

Run:
    PYTORCH_ENABLE_MPS_FALLBACK=1 AEIC_DEVICE=cpu .venv/bin/python exp/export_golden.py
    ... --all           # all 26 images instead of the default 10
    ... --no-verify     # skip the in-process decode round-trip (faster)
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
import torch.nn.functional as F

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(HERE))

import aeic_runner as R  # noqa: E402

OUT = ROOT / "results" / "golden"
VEC = OUT / "vectors"

# default corpus: 8 Kodak + the 2 custom images
DEFAULT_IMAGES = [
    "kodim01", "kodim02", "kodim05", "kodim08",
    "kodim13", "kodim19", "kodim23", "kodim24",
    "image2", "images",
]

TABLE_MAGIC = b"AEICCDF\x01"   # 8 bytes
GV_MAGIC = b"AEICGV\x00\x01"   # 8 bytes
FORMAT_VERSION = 1
PRECISION = 16                 # rANS probability precision, bits
BYPASS_PRECISION = 2
STREAM_PARTS = 2               # EntropyCoder() -> RansEncoder(ec_thread, 2)

DT_INT16 = 0
DT_INT32 = 1


class _IdentityGS(torch.nn.Module):
    """Stand-in for codec.g_s: hand the latent straight back, no UNet/VAE."""

    def forward(self, y_hat):
        return y_hat, None


# --------------------------------------------------------------------------- tables

def write_table_file(codec, path):
    """Serialize both CDF groups + the index-quantizer constants.

    Layout (all little-endian, no padding, no alignment guarantees beyond 4 bytes):

        char[8]  magic  = "AEICCDF\x01"
        u32      version                = 1
        u32      precision              = 16
        u32      bypass_precision       = 2
        u32      stream_parts           = 2
        u32      num_groups             = 2
        -- then num_groups group blocks, in order (group 0 = z, group 1 = y):
        u32      num_cdfs   R
        u32      cdf_width  W
        i32[R]   cdf_length
        i32[R]   offset
        i32[R*W] quantized_cdf, row-major
        -- then one index-quantizer block:
        char[4]  "IDXP"
        f64      log_scale_min
        f64      log_scale_step
        u32      scales_levels           = 64
        f32      scale_bound_lo          = 0.08   (scales below this -> index -1)
        f32      scale_floor             = 1e-5   (torch.maximum floor)
        f32[64]  scale_table
        -- trailer:
        char[4]  "END\x00"
    """
    z_cdf = np.asarray(codec.z_quantized_cdf, dtype=np.int32)
    z_len = np.asarray(codec.z_cdf_length, dtype=np.int32).reshape(-1)
    z_off = np.asarray(codec.z_offset, dtype=np.int32).reshape(-1)
    y_cdf = np.asarray(codec.y_quantized_cdf, dtype=np.int32)
    y_len = np.asarray(codec.y_cdf_length, dtype=np.int32).reshape(-1)
    y_off = np.asarray(codec.y_offset, dtype=np.int32).reshape(-1)

    groups = [("z", z_cdf, z_len, z_off), ("y", y_cdf, y_len, y_off)]

    buf = bytearray()
    buf += TABLE_MAGIC
    buf += struct.pack("<5I", FORMAT_VERSION, PRECISION, BYPASS_PRECISION,
                       STREAM_PARTS, len(groups))
    meta = []
    for name, cdf, ln, off in groups:
        assert cdf.ndim == 2, (name, cdf.shape)
        r, w = cdf.shape
        assert ln.shape == (r,) and off.shape == (r,), (name, ln.shape, off.shape)
        assert int(ln.max()) <= w, (name, int(ln.max()), w)
        assert cdf.min() >= 0 and cdf.max() <= (1 << PRECISION), (name, cdf.min(), cdf.max())
        buf += struct.pack("<2I", r, w)
        buf += ln.astype("<i4").tobytes()
        buf += off.astype("<i4").tobytes()
        buf += np.ascontiguousarray(cdf).astype("<i4").tobytes()
        meta.append({
            "group": name, "rows": int(r), "width": int(w),
            "cdf_length_min": int(ln.min()), "cdf_length_max": int(ln.max()),
            "offset_min": int(off.min()), "offset_max": int(off.max()),
            "cdf_max": int(cdf.max()),
        })

    scale_table = codec.gaussian_conditional.scale_table.detach().cpu().numpy()
    scale_table = np.asarray(scale_table, dtype=np.float32).reshape(-1)
    buf += b"IDXP"
    buf += struct.pack("<2d", float(codec.my_log_scale_min), float(codec.my_log_scale_step))
    buf += struct.pack("<I", int(scale_table.size))
    buf += struct.pack("<2f", 0.08, 1e-5)
    buf += scale_table.astype("<f4").tobytes()
    buf += b"END\x00"

    path.write_bytes(bytes(buf))
    n = os.stat(path).st_size
    assert n == len(buf), (n, len(buf))
    return n, meta


# ------------------------------------------------------------------- golden vectors

def write_gv_file(path, arrays):
    """Compact container for the integer arrays fed to rANS.

        char[8]  magic = "AEICGV\x00\x01"
        u32      version    = 1
        u32      n_arrays
        -- n_arrays descriptors, fixed 24 bytes each:
           char[16] name, NUL-padded
           u32      dtype   (0 = int16, 1 = int32)
           u32      count   (elements)
        -- then the payloads back to back, in descriptor order, little-endian.
    """
    buf = bytearray()
    buf += GV_MAGIC
    buf += struct.pack("<2I", FORMAT_VERSION, len(arrays))
    payload = bytearray()
    for name, arr in arrays:
        assert len(name) <= 16, name
        dt = DT_INT16 if arr.dtype == np.int16 else DT_INT32
        assert arr.dtype in (np.dtype(np.int16), np.dtype(np.int32)), (name, arr.dtype)
        buf += name.encode("ascii").ljust(16, b"\x00")
        buf += struct.pack("<2I", dt, int(arr.size))
        payload += np.ascontiguousarray(arr).astype("<i2" if dt == DT_INT16 else "<i4").tobytes()
    buf += payload
    path.write_bytes(bytes(buf))
    n = os.stat(path).st_size
    assert n == len(buf), (n, len(buf))
    return n


def parse_container(stream):
    """Mirror of RansDecoder::set_stream -- split the shipped bytes into sub-streams."""
    flag = stream[0]
    n_streams = (flag >> 4) + 1
    hdr = 2 if (flag & 0x0F) == 1 else 4
    off = 1
    sizes, total = [], 0
    for _ in range(n_streams - 1):
        if hdr == 2:
            sz = int.from_bytes(stream[off:off + 2], "little")
        else:
            sz = int.from_bytes(stream[off:off + 4], "little")
        off += hdr
        sizes.append(sz)
        total += sz
    sizes.append(len(stream) - off - total)
    parts, p = [], off
    for sz in sizes:
        parts.append(stream[p:p + sz])
        p += sz
    assert p == len(stream), (p, len(stream))
    return flag, hdr, sizes, parts


@torch.no_grad()
def capture(codec, x):
    """Verbatim codec_practical.AEIC_Codec.compress(), capturing every rANS input."""
    B, C, H, W = x.shape
    y_h, y_w = H // 32, W // 32
    z_h, z_w = math.ceil(y_h / 4), math.ceil(y_w / 4)
    pad_h, pad_w = z_h * 4 - y_h, z_w * 4 - y_w

    masks = codec.get_mask_four_parts(1, codec.y_channel, y_h, y_w, device=x.device)
    z_indexes, z_offset = codec.entropy_bottleneck.get_compress_info(
        [1, codec.y_channel // 2, z_h, z_w])

    y = codec.g_a(x)
    y_padded = F.pad(y, (0, pad_w, 0, pad_h), mode="reflect")
    z = codec.h_a(y_padded)
    z_q = torch.round(z - z_offset)
    z_hat = (z_q + z_offset).contiguous()
    z_q_np = z_q.flatten().cpu().numpy()

    base = codec.h_s(z_hat)[:, :, :y_h, :y_w]
    y_q_list, scales_list, last = [], [], None
    for i in range(4):
        mask = masks[i]
        out = codec.adapter_out[i](codec.g_c(codec.adapter_in[i](base)))
        means_supp, scales_supp = out.chunk(2, 1)
        means = means_supp * mask
        scales = scales_supp * mask
        y_q = torch.round(y * mask - means)
        y_q_list.append(y_q)
        scales_list.append(scales)
        last = y_q + means
        if i < 3:
            base = base * (1 - mask) + last
    y_hat_enc = base * (1 - masks[3]) + last

    packed = codec.compress_group(y_q_list, scales_list)
    yq = list(packed[:4])
    yidx = list(packed[4:])

    codec.entropy_coder.reset()
    codec.entropy_coder.encode_with_z4y_indexes(
        z_q_np, z_indexes, codec.z_cdf_group_index,
        yq[0], yidx[0], yq[1], yidx[1], yq[2], yidx[2], yq[3], yidx[3],
        codec.y_cdf_group_index)
    codec.entropy_coder.flush()
    stream = codec.entropy_coder.get_encoded_stream()

    # exactly the int16 the pybind layer forcecasts to
    z_q_i16 = z_q_np.astype(np.int16)
    z_idx_i16 = z_indexes.reshape(-1).cpu().numpy().astype(np.int16)
    yq_i16 = [a.reshape(-1).astype(np.int16) for a in yq]
    yidx_i16 = [a.reshape(-1).astype(np.int16) for a in yidx]

    # the forcecast must be lossless: assert the float/int32 originals round-trip
    assert np.array_equal(z_q_i16.astype(np.float64), z_q_np.astype(np.float64))
    for a, b in zip(yq_i16, yq):
        assert np.array_equal(a.astype(np.float64), b.reshape(-1).astype(np.float64))
    for a, b in zip(yidx_i16, yidx):
        assert np.array_equal(a.astype(np.int64), b.reshape(-1).astype(np.int64))

    return {
        "stream": stream,
        "y_hat_enc": y_hat_enc,
        "z_q": z_q_i16, "z_indexes": z_idx_i16,
        "yq": yq_i16, "yidx": yidx_i16,
        "shapes": {"y": list(y.shape), "z": list(z.shape),
                   "z_q_n": int(z_q_i16.size), "yq_n": int(yq_i16[0].size)},
    }


def make_synthetic(codec):
    """Cases the real corpus never reaches: escape / bypass coding and skipped indexes.

    On ft32 the live symbols are tiny (y_q in [-2,2], z_q in [-3,2]) and sit far from
    both ends of their CDF row, so `value == max_value` never fires and the whole
    bypass branch of the coder is dead. A Dart port that got it wrong would still
    pass every image vector. These hand-built cases exercise it.

    All arrays have EVEN length: py_rans splits each array in half across the two
    encoders and its last-part memcpy over-runs the index vector when the length is
    odd. Never feed it an odd-length array.
    """
    zg, yg = int(codec.z_cdf_group_index), int(codec.y_cdf_group_index)
    z_len = np.asarray(codec.z_cdf_length).reshape(-1).astype(np.int64)
    z_off = np.asarray(codec.z_offset).reshape(-1).astype(np.int64)
    y_len = np.asarray(codec.y_cdf_length).reshape(-1).astype(np.int64)
    y_off = np.asarray(codec.y_offset).reshape(-1).astype(np.int64)

    def i16(a):
        return np.asarray(a, dtype=np.int16)

    cases = []

    # --- group z: value == max_value exactly (escape with raw_val == 0, n_bypass == 0)
    idx = np.arange(0, 128, dtype=np.int64)
    sym = z_off[idx] + (z_len[idx] - 2)            # value == max_value
    cases.append(("z_escape_exact", zg, i16(sym), i16(idx)))

    # --- group z: value < 0 (odd raw_val) and value > max_value (even raw_val), mixed
    sym = np.where(idx % 2 == 0, z_off[idx] - 1 - (idx // 2), z_off[idx] + z_len[idx] + idx)
    cases.append(("z_escape_mixed", zg, i16(sym), i16(idx)))

    # --- group z: every in-range symbol of every row, tiled (normal path, all rows)
    reps = 16
    idx2 = np.repeat(idx, reps)
    k = np.tile(np.arange(reps, dtype=np.int64), 128) % np.repeat(z_len[idx] - 2, reps)
    cases.append(("z_dense_normal", zg, i16(z_off[idx2] + k), i16(idx2)))

    # --- group y: huge magnitudes -> long bypass runs (n_bypass >= 3 exercises the
    #     max_bypass_val continuation loop)
    idx = np.arange(0, 64, dtype=np.int64)
    big = np.array([32000, -32000, 20000, -20000, 4096, -4096, 3132, -3132], dtype=np.int64)
    idx3 = np.repeat(idx, len(big))
    sym = np.tile(big, 64)
    cases.append(("y_bypass_long", yg, i16(sym), i16(idx3)))

    # --- group y: index -1 must be skipped by the encoder and decode to 0
    idx4 = np.where(np.arange(128) % 3 == 0, -1, np.arange(128) % 64).astype(np.int64)
    sym4 = np.where(idx4 < 0, 12345, y_off[np.maximum(idx4, 0)] + 1).astype(np.int64)
    cases.append(("y_skip_indexes", yg, i16(sym4), i16(idx4)))

    # --- group y: near both edges of each row, without escaping
    idx5 = np.repeat(idx, 4)
    edge = np.tile(np.array([0, 1, -3, -2], dtype=np.int64), 64)
    ml = np.repeat(y_len[idx] - 2, 4)
    val = np.where(edge >= 0, edge, ml + edge)
    cases.append(("y_edges_normal", yg, i16(y_off[idx5] + val), i16(idx5)))

    # --- smallest possible payload: two symbols
    cases.append(("y_tiny", yg, i16([y_off[0], y_off[0] + 1]), i16([0, 0])))

    for name, g, s, i in cases:
        assert s.size == i.size and s.size % 2 == 0, (name, s.size, i.size)
    return cases


def most_likely_symbol(cdf_row, cdf_len, offset):
    """(symbol, cost-free-ish) -- the highest-frequency value of a CDF row.

    Used as filler: see pad_case().
    """
    n = int(cdf_len) - 2
    freqs = [int(cdf_row[j + 1]) - int(cdf_row[j]) for j in range(n)]
    j = int(np.argmax(freqs))
    return int(offset) + j


def encode_case(codec, group, sym, idx):
    codec.entropy_coder.reset()
    codec.entropy_coder.encoder.encode_with_indexes(sym, idx, group)
    codec.entropy_coder.flush()
    return codec.entropy_coder.get_encoded_stream()


def pad_case(codec, group, sym, idx, cdfs, lens, offs):
    """Pad a synthetic case until it is safe for the SHIPPED C++ encoder.

    RansEncoderLib::flush() allocates exactly `_syms.size()` output bytes and writes
    backwards from the end, so any sub-stream longer than one byte per pushed symbol
    ENTRY runs off the front of the allocation. That is a silent heap under-run: the
    bytes are still readable on this platform so the call appears to succeed, but it
    scribbles on the allocator and poisons every later encode in the process.
    Escape/bypass symbols cost up to 16 bits each and blow that budget easily.

    So the search must never hand an unsafe case to the C++ encoder. Sizing is done
    entirely with the pure-Python reference port below (which selfcheck() proves is
    byte-identical to the C++ coder on the real image vectors), and the C++ encoder
    is called exactly once, on an already-verified-safe case.
    """
    row = int(idx[idx >= 0][0]) if (idx >= 0).any() else 0
    fill_sym = most_likely_symbol(cdfs[row], lens[row], offs[row])
    tbl = {group: (cdfs, lens, offs)}
    n_fill = 64
    for _ in range(24):
        fa = np.full(n_fill, fill_sym, dtype=np.int16)
        ia = np.full(n_fill, row, dtype=np.int16)
        s = np.concatenate([fa, sym, fa]).astype(np.int16)
        i = np.concatenate([ia, idx, ia]).astype(np.int16)
        assert s.size % 2 == 0
        each = s.size // 2
        safe = True
        for p in range(STREAM_PARTS):
            lo = p * each
            hi = s.size if p == STREAM_PARTS - 1 else lo + each
            ent = []
            ref_push_symbols(ent, s[lo:hi], i[lo:hi], cdfs, lens, offs)
            if len(ref_flush(ent)) * 2 > len(ent):     # demand 2x headroom
                safe = False
                break
        if safe:
            return s, i, n_fill
        n_fill *= 2
    raise RuntimeError("could not pad case into the C++ encoder's byte budget")


def run_synthetic(codec, cases):
    tables = {
        int(codec.z_cdf_group_index): (np.asarray(codec.z_quantized_cdf),
                                       np.asarray(codec.z_cdf_length).reshape(-1),
                                       np.asarray(codec.z_offset).reshape(-1)),
        int(codec.y_cdf_group_index): (np.asarray(codec.y_quantized_cdf),
                                       np.asarray(codec.y_cdf_length).reshape(-1),
                                       np.asarray(codec.y_offset).reshape(-1)),
    }
    rows = []
    for name, group, sym0, idx0 in cases:
        cdfs, lens, offs = tables[group]
        sym, idx, n_fill = pad_case(codec, group, sym0, idx0, cdfs, lens, offs)
        stream = encode_case(codec, group, sym, idx)

        bin_path = VEC / f"synth_{name}.bin"
        bin_path.write_bytes(stream)
        st = os.stat(bin_path).st_size
        assert st == len(stream), f"{name}: stat {st} != len {len(stream)}"

        flag, hdr, sizes, parts = parse_container(stream)
        gv_path = VEC / f"synth_{name}.gv"
        gv_bytes = write_gv_file(gv_path, [("symbols", sym), ("indexes", idx)])

        # decode back through the C++ decoder; index<0 positions decode to 0
        codec.entropy_coder.decoder.set_stream(np.frombuffer(stream, dtype=np.uint8))
        dec = np.asarray(codec.entropy_coder.decoder.decode_stream(idx, group))
        expect = np.where(idx < 0, 0, sym).astype(np.int16)
        ok = bool(np.array_equal(dec.astype(np.int16), expect))
        assert ok, f"{name}: decoder disagreed"

        rows.append({
            "name": name, "cdf_group": int(group), "n": int(sym.size),
            "n_filler_each_end": int(n_fill),
            "bitstream_file": bin_path.name, "bitstream_bytes_stat": st,
            "bitstream_sha256": hashlib.sha256(stream).hexdigest(),
            "container_flag": flag, "container_header_bytes": hdr,
            "substream_sizes": sizes,
            "vector_file": gv_path.name, "vector_bytes_stat": gv_bytes,
            "expected_decode_sha256": hashlib.sha256(
                expect.astype("<i2").tobytes()).hexdigest(),
            "sym_min": int(sym.min()), "sym_max": int(sym.max()),
            "n_skipped": int((idx < 0).sum()),
            "roundtrip_exact": ok,
        })
        print(f"  synth_{name:<16} n={sym.size:<5} {st:>6} B parts={sizes} "
              f"sym[{sym.min()},{sym.max()}] skip={int((idx<0).sum())} rt={ok}", flush=True)
    return rows


# ------------------------------------------------- independent reference port
# A from-scratch re-implementation of the C++ coder, written the way the Dart port
# should be written (plain ints, growable buffer, no numpy tricks). If this
# reproduces every golden bitstream byte-for-byte then results/rans_port_spec.md is
# correct and a Dart implementer never has to open the C++.

RANS_L = 1 << 23
MAX_BYPASS_VAL = (1 << BYPASS_PRECISION) - 1


def ref_push_symbols(out, symbols, indexes, cdfs, cdf_lengths, offsets):
    """Append (start, range) entries for one encode_with_indexes() call."""
    for i in range(len(symbols)):
        cdf_idx = int(indexes[i])
        if cdf_idx < 0:
            continue
        max_value = int(cdf_lengths[cdf_idx]) - 2
        value = int(symbols[i]) - int(offsets[cdf_idx])
        raw_val = 0
        if value < 0:
            raw_val = -2 * value - 1
            value = max_value
        elif value >= max_value:
            raw_val = 2 * (value - max_value)
            value = max_value
        row = cdfs[cdf_idx]
        out.append((int(row[value]), int(row[value + 1]) - int(row[value])))
        if value == max_value:
            n_bypass = 0
            while (raw_val >> (n_bypass * BYPASS_PRECISION)) != 0:
                n_bypass += 1
            val = n_bypass
            while val >= MAX_BYPASS_VAL:
                out.append((MAX_BYPASS_VAL, 0))
                val -= MAX_BYPASS_VAL
            out.append((val, 0))
            for j in range(n_bypass):
                out.append(((raw_val >> (j * BYPASS_PRECISION)) & MAX_BYPASS_VAL, 0))


def ref_flush(entries):
    """rANS encode the entry list in reverse; returns the sub-stream bytes."""
    rev = bytearray()          # bytes in emission order == reverse of stream order
    x = RANS_L
    for start, rng in reversed(entries):
        if rng != 0:
            x_max = rng << 15
            while x >= x_max:
                rev.append(x & 0xFF)
                x >>= 8
            x = ((x // rng) << PRECISION) + (x % rng) + start
        else:
            x_max = (1 << (PRECISION - BYPASS_PRECISION)) << 15
            while x >= x_max:
                rev.append(x & 0xFF)
                x >>= 8
            x = (x << BYPASS_PRECISION) | start
    rev.append((x >> 24) & 0xFF)
    rev.append((x >> 16) & 0xFF)
    rev.append((x >> 8) & 0xFF)
    rev.append(x & 0xFF)
    rev.reverse()
    return bytes(rev)


def ref_container(parts):
    maximum = max((len(p) for p in parts[:-1]), default=0)
    hdr = 4 if maximum > 65535 else 2
    flag = ((len(parts) - 1) << 4) | (1 if hdr == 2 else 0)
    out = bytearray([flag])
    for p in parts[:-1]:
        out += len(p).to_bytes(hdr, "little")
    for p in parts:
        out += p
    return bytes(out)


def ref_encode(calls, tables, n_parts=STREAM_PARTS):
    """calls: list of (symbols, indexes, cdf_group). Returns the shipped bytes."""
    entries = [[] for _ in range(n_parts)]
    for symbols, indexes, group in calls:
        cdfs, lens, offs = tables[group]
        total = len(symbols)
        each = total // n_parts
        for p in range(n_parts):
            lo = p * each
            hi = total if p == n_parts - 1 else lo + each
            ref_push_symbols(entries[p], symbols[lo:hi], indexes[lo:hi], cdfs, lens, offs)
    return ref_container([ref_flush(e) for e in entries])


def ref_decode(stream, index_calls, tables, n_parts=STREAM_PARTS):
    """index_calls: list of (indexes, cdf_group). Returns list of symbol lists."""
    _, _, _, parts = parse_container(stream)
    states, ptrs = [], []
    for p in parts:
        states.append(int.from_bytes(p[0:4], "little"))
        ptrs.append(4)
    results = []
    for indexes, group in index_calls:
        cdfs, lens, offs = tables[group]
        total = len(indexes)
        each = total // n_parts
        out = [0] * total
        for pi in range(n_parts):
            lo = pi * each
            hi = total if pi == n_parts - 1 else lo + each
            buf = parts[pi]
            x = states[pi]
            ptr = ptrs[pi]
            for i in range(lo, hi):
                cdf_idx = int(indexes[i])
                if cdf_idx < 0:
                    out[i] = 0
                    continue
                row = cdfs[cdf_idx]
                n = int(lens[cdf_idx])
                max_value = n - 2
                cum = x & ((1 << PRECISION) - 1)
                s = -1                      # upper_bound(row[0:n], cum) - 1
                loo, hii = 0, n
                while loo < hii:
                    mid = (loo + hii) // 2
                    if int(row[mid]) > cum:
                        hii = mid
                    else:
                        loo = mid + 1
                s = loo - 1
                start = int(row[s])
                rng = int(row[s + 1]) - start
                x = rng * (x >> PRECISION) + (x & ((1 << PRECISION) - 1)) - start
                if x < RANS_L:
                    while x < RANS_L:
                        x = ((x << 8) | buf[ptr]) & 0xFFFFFFFF
                        ptr += 1
                value = s
                if value == max_value:
                    def get_bits(nb, _x=None):
                        nonlocal x, ptr
                        v = x & ((1 << nb) - 1)
                        x >>= nb
                        if x < RANS_L:
                            x = ((x << 8) | buf[ptr]) & 0xFFFFFFFF
                            ptr += 1
                        return v
                    val = get_bits(BYPASS_PRECISION)
                    n_bypass = val
                    while val == MAX_BYPASS_VAL:
                        val = get_bits(BYPASS_PRECISION)
                        n_bypass += val
                    raw_val = 0
                    for j in range(n_bypass):
                        raw_val |= get_bits(BYPASS_PRECISION) << (j * BYPASS_PRECISION)
                    value = raw_val >> 1
                    if raw_val & 1:
                        value = -value - 1
                    else:
                        value += max_value
                out[i] = value + int(offs[cdf_idx])
            states[pi] = x
            ptrs[pi] = ptr
        results.append(out)
    return results


def selfcheck(codec, manifest):
    """Re-encode and re-decode every golden vector with the reference port."""
    tables = {
        int(codec.z_cdf_group_index): (np.asarray(codec.z_quantized_cdf),
                                       np.asarray(codec.z_cdf_length).reshape(-1),
                                       np.asarray(codec.z_offset).reshape(-1)),
        int(codec.y_cdf_group_index): (np.asarray(codec.y_quantized_cdf),
                                       np.asarray(codec.y_cdf_length).reshape(-1),
                                       np.asarray(codec.y_offset).reshape(-1)),
    }
    zg, yg = int(codec.z_cdf_group_index), int(codec.y_cdf_group_index)
    n_ok = n_tot = 0

    for rec in manifest["images"]:
        arrs = read_gv_file(VEC / rec["vector_file"])
        calls = [(arrs["z_q"], arrs["z_indexes"], zg)]
        calls += [(arrs[f"y_q{i}"], arrs[f"y_indexes{i}"], yg) for i in range(4)]
        want = (VEC / rec["bitstream_file"]).read_bytes()
        got = ref_encode(calls, tables)
        enc_ok = got == want
        dec = ref_decode(want, [(c[1], c[2]) for c in calls], tables)
        dec_ok = all(
            list(d) == [0 if int(ix) < 0 else int(sy) for sy, ix in zip(c[0], c[1])]
            for d, c in zip(dec, calls))
        n_tot += 1
        n_ok += int(enc_ok and dec_ok)
        print(f"  ref {rec['stem']:<10} encode={'OK' if enc_ok else 'MISMATCH'} "
              f"decode={'OK' if dec_ok else 'MISMATCH'} ({len(got)}/{len(want)} B)")

    for rec in manifest["synthetic"]:
        arrs = read_gv_file(VEC / rec["vector_file"])
        g = rec["cdf_group"]
        calls = [(arrs["symbols"], arrs["indexes"], g)]
        want = (VEC / rec["bitstream_file"]).read_bytes()
        got = ref_encode(calls, tables)
        enc_ok = got == want
        dec = ref_decode(want, [(arrs["indexes"], g)], tables)
        expect = [0 if int(ix) < 0 else int(sy)
                  for sy, ix in zip(arrs["symbols"], arrs["indexes"])]
        dec_ok = list(dec[0]) == expect
        n_tot += 1
        n_ok += int(enc_ok and dec_ok)
        print(f"  ref synth_{rec['name']:<16} encode={'OK' if enc_ok else 'MISMATCH'} "
              f"decode={'OK' if dec_ok else 'MISMATCH'} ({len(got)}/{len(want)} B)")

    print(f"reference port reproduces {n_ok}/{n_tot} vectors exactly")
    return n_ok, n_tot


def read_gv_file(path):
    raw = path.read_bytes()
    assert raw[:8] == GV_MAGIC, path
    ver, n = struct.unpack_from("<2I", raw, 8)
    assert ver == FORMAT_VERSION
    off = 16
    descs = []
    for _ in range(n):
        name = raw[off:off + 16].rstrip(b"\x00").decode()
        dt, cnt = struct.unpack_from("<2I", raw, off + 16)
        descs.append((name, dt, cnt))
        off += 24
    out = {}
    for name, dt, cnt in descs:
        w = 2 if dt == DT_INT16 else 4
        out[name] = np.frombuffer(raw, dtype="<i2" if w == 2 else "<i4",
                                  count=cnt, offset=off)
        off += cnt * w
    assert off == len(raw), (off, len(raw))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ckpt", default="AEIC_SE_ft32.pkl")
    ap.add_argument("--size", type=int, default=512)
    ap.add_argument("--all", action="store_true", help="use all 26 images")
    ap.add_argument("--no-verify", action="store_true")
    args = ap.parse_args()

    all_images = sorted((ROOT / "data" / "kodak_raw").glob("*.png"))
    all_images += sorted(p for p in (ROOT / "data" / "custom").iterdir() if p.is_file())
    if args.all:
        images = all_images
    else:
        by_stem = {p.stem: p for p in all_images}
        images = [by_stem[s] for s in DEFAULT_IMAGES if s in by_stem]
    print(f"{len(images)} images, ckpt={args.ckpt}, size={args.size}")

    OUT.mkdir(parents=True, exist_ok=True)
    VEC.mkdir(parents=True, exist_ok=True)

    net, _ = R.load_model(ckpt=args.ckpt)
    codec = net.codec
    print("codec.update(force=True) ->", codec.update(force=True))
    real_g_s = codec._modules.pop("g_s")
    codec.g_s = _IdentityGS()

    tbl_path = OUT / "aeic_cdf_ft32.bin"
    tbl_bytes, tbl_meta = write_table_file(codec, tbl_path)
    tbl_sha = hashlib.sha256(tbl_path.read_bytes()).hexdigest()
    print(f"tables -> {tbl_path.name}  {tbl_bytes} B  sha256={tbl_sha[:16]}")
    for m in tbl_meta:
        print(f"   group {m['group']}: {m['rows']}x{m['width']}  "
              f"cdf_length {m['cdf_length_min']}..{m['cdf_length_max']}  "
              f"offset {m['offset_min']}..{m['offset_max']}  cdf_max {m['cdf_max']}")

    z_h = math.ceil((args.size // 32) / 4)
    rows = []
    for path in images:
        x = R.load_image(str(path), size=args.size)
        cap = capture(codec, x)
        stream = cap["stream"]
        stem = path.stem

        bin_path = VEC / f"{stem}.bin"
        bin_path.write_bytes(stream)
        st = os.stat(bin_path).st_size
        assert st == len(stream), f"{stem}: stat {st} != len {len(stream)}"

        flag, hdr, sizes, parts = parse_container(stream)
        assert sum(sizes) + 1 + hdr * (len(sizes) - 1) == st

        arrays = [("z_q", cap["z_q"]), ("z_indexes", cap["z_indexes"])]
        for i in range(4):
            arrays.append((f"y_q{i}", cap["yq"][i]))
        for i in range(4):
            arrays.append((f"y_indexes{i}", cap["yidx"][i]))
        gv_path = VEC / f"{stem}.gv"
        gv_bytes = write_gv_file(gv_path, arrays)

        ok = None
        if not args.no_verify:
            codec.entropy_coder.reset()
            codec.entropy_coder.set_stream(stream)
            y_hat_dec, _ = codec.decompress(
                (1, codec.y_channel // 2, z_h, z_h), args.size // 32, args.size // 32)
            ok = bool(torch.equal(cap["y_hat_enc"], y_hat_dec))
            assert ok, f"{stem}: round-trip not bit-exact"

        rec = {
            "image": path.name,
            "stem": stem,
            "bitstream_file": bin_path.name,
            "bitstream_bytes_stat": st,
            "bitstream_sha256": hashlib.sha256(stream).hexdigest(),
            "container_flag": flag,
            "container_header_bytes": hdr,
            "substream_sizes": sizes,
            "substream_sha256": [hashlib.sha256(p).hexdigest() for p in parts],
            "vector_file": gv_path.name,
            "vector_bytes_stat": gv_bytes,
            "n_z_symbols": int(cap["z_q"].size),
            "n_y_symbols_each": int(cap["yq"][0].size),
            "z_q_min": int(cap["z_q"].min()), "z_q_max": int(cap["z_q"].max()),
            "y_q_min": int(min(a.min() for a in cap["yq"])),
            "y_q_max": int(max(a.max() for a in cap["yq"])),
            "y_index_min": int(min(a.min() for a in cap["yidx"])),
            "y_index_max": int(max(a.max() for a in cap["yidx"])),
            "n_skipped_y_indexes": int(sum(int((a < 0).sum()) for a in cap["yidx"])),
            "roundtrip_bitexact": ok,
        }
        rows.append(rec)
        print(f"  {stem:<10} {st:>4} B  parts={sizes}  gv={gv_bytes} B  "
              f"z_q[{rec['z_q_min']},{rec['z_q_max']}] "
              f"y_q[{rec['y_q_min']},{rec['y_q_max']}] "
              f"idx[{rec['y_index_min']},{rec['y_index_max']}] "
              f"skip={rec['n_skipped_y_indexes']} rt={ok}", flush=True)

    print("synthetic (escape / bypass / skip coverage):")
    synth = run_synthetic(codec, make_synthetic(codec))

    codec._modules["g_s"] = real_g_s

    manifest = {
        "checkpoint": args.ckpt,
        "size": args.size,
        "precision": PRECISION,
        "bypass_precision": BYPASS_PRECISION,
        "stream_parts": STREAM_PARTS,
        "table_file": tbl_path.name,
        "table_bytes": tbl_bytes,
        "table_sha256": tbl_sha,
        "table_groups": tbl_meta,
        "z_cdf_group_index": int(codec.z_cdf_group_index),
        "y_cdf_group_index": int(codec.y_cdf_group_index),
        "images": rows,
        "synthetic": synth,
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=1))

    print("\nreference-port self-check (validates results/rans_port_spec.md):")
    ok, tot = selfcheck(codec, manifest)
    manifest["reference_port_selfcheck"] = {"ok": ok, "total": tot}
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=1))
    assert ok == tot, "reference port does not match the C++ coder"

    n = len(rows)
    b = [r["bitstream_bytes_stat"] for r in rows]
    print(f"\n{n} vectors, bitstream {min(b)}-{max(b)} B mean {sum(b)/n:.1f}")
    print(f"round-trip bit-exact {sum(1 for r in rows if r['roundtrip_bitexact'])}/{n}")
    print(f"wrote {OUT / 'manifest.json'}")


if __name__ == "__main__":
    main()
