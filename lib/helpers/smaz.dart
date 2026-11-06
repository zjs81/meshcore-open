import 'dart:convert';
import 'dart:typed_data';

class Smaz {
  static const int _verbatimSingle = 254;
  static const int _verbatimRun = 255;

  static const List<String> _rcb = [
    " ",
    "the",
    "e",
    "t",
    "a",
    "of",
    "o",
    "and",
    "i",
    "n",
    "s",
    "e ",
    "r",
    " th",
    " t",
    "in",
    "he",
    "th",
    "h",
    "he ",
    "to",
    "\r\n",
    "l",
    "s ",
    "d",
    " a",
    "an",
    "er",
    "c",
    " o",
    "d ",
    "on",
    " of",
    "re",
    "of ",
    "t ",
    ", ",
    "is",
    "u",
    "at",
    "   ",
    "n ",
    "or",
    "which",
    "f",
    "m",
    "as",
    "it",
    "that",
    "\n",
    "was",
    "en",
    "  ",
    " w",
    "es",
    " an",
    " i",
    "\r",
    "f ",
    "g",
    "p",
    "nd",
    " s",
    "nd ",
    "ed ",
    "w",
    "ed",
    "http://",
    "for",
    "te",
    "ing",
    "y ",
    "The",
    " c",
    "ti",
    "r ",
    "his",
    "st",
    " in",
    "ar",
    "nt",
    ",",
    " to",
    "y",
    "ng",
    " h",
    "with",
    "le",
    "al",
    "to ",
    "b",
    "ou",
    "be",
    "were",
    " b",
    "se",
    "o ",
    "ent",
    "ha",
    "ng ",
    "their",
    "\"",
    "hi",
    "from",
    " f",
    "in ",
    "de",
    "ion",
    "me",
    "v",
    ".",
    "ve",
    "all",
    "re ",
    "ri",
    "ro",
    "is ",
    "co",
    "f t",
    "are",
    "ea",
    ". ",
    "her",
    " m",
    "er ",
    " p",
    "es ",
    "by",
    "they",
    "di",
    "ra",
    "ic",
    "not",
    "s, ",
    "d t",
    "at ",
    "ce",
    "la",
    "h ",
    "ne",
    "as ",
    "tio",
    "on ",
    "n t",
    "io",
    "we",
    " a ",
    "om",
    ", a",
    "s o",
    "ur",
    "li",
    "ll",
    "ch",
    "had",
    "this",
    "e t",
    "g ",
    "e\r\n",
    " wh",
    "ere",
    " co",
    "e o",
    "a ",
    "us",
    " d",
    "ss",
    "\n\r\n",
    "\r\n\r",
    "=\"",
    " be",
    " e",
    "s a",
    "ma",
    "one",
    "t t",
    "or ",
    "but",
    "el",
    "so",
    "l ",
    "e s",
    "s,",
    "no",
    "ter",
    " wa",
    "iv",
    "ho",
    "e a",
    " r",
    "hat",
    "s t",
    "ns",
    "ch ",
    "wh",
    "tr",
    "ut",
    "/",
    "have",
    "ly ",
    "ta",
    " ha",
    " on",
    "tha",
    "-",
    " l",
    "ati",
    "en ",
    "pe",
    " re",
    "there",
    "ass",
    "si",
    " fo",
    "wa",
    "ec",
    "our",
    "who",
    "its",
    "z",
    "fo",
    "rs",
    ">",
    "ot",
    "un",
    "<",
    "im",
    "th ",
    "nc",
    "ate",
    "><",
    "ver",
    "ad",
    " we",
    "ly",
    "ee",
    " n",
    "id",
    " cl",
    "ac",
    "il",
    "</",
    "rt",
    " wi",
    "div",
    "e, ",
    " it",
    "whi",
    " ma",
    "ge",
    "x",
    "e c",
    "men",
    ".com",
  ];

  static final List<Uint8List> _rcbBytes = _rcb
      .map((s) => Uint8List.fromList(ascii.encode(s)))
      .toList(growable: false);
  static final int _maxEntryLen = _rcbBytes.fold(0, (maxLen, entry) {
    return entry.length > maxLen ? entry.length : maxLen;
  });

  static String encodeIfSmaller(String text) {
    if (text.isEmpty || text.startsWith('s:')) return text;
    final originalBytes = Uint8List.fromList(utf8.encode(text));
    final compressed = compressBytes(originalBytes);
    final encoded = base64Encode(compressed);
    final candidate = 's:$encoded';
    if (utf8.encode(candidate).length < originalBytes.length) {
      return candidate;
    }
    return text;
  }

  /// Decodes text produced by [encodeIfSmaller]. Returns null when [text] is
  /// not a compressed payload.
  ///
  /// Plain text can also start with `s:` followed by base64-looking
  /// characters ("s:test"), so a payload only counts as compressed when it
  /// satisfies the encoder's invariants: valid UTF-8, re-compressing the
  /// result yields the same bytes, and the encoded form is shorter than the
  /// decoded text. Very short ambiguous inputs can still match.
  static String? tryDecodePrefixed(String text) {
    final trimmedLeft = text.trimLeft();
    if (!trimmedLeft.startsWith('s:') || trimmedLeft.length <= 2) return null;
    final encoded = trimmedLeft.substring(2);
    try {
      final compressed = _decodeBase64Flexible(encoded);
      if (compressed.isEmpty) return null;
      final decompressed = decompressBytes(compressed);
      final decoded = utf8.decode(decompressed);
      final recompressed = compressBytes(decompressed);
      if (!_bytesEqual(recompressed, compressed)) return null;
      final candidateLength = 2 + base64Encode(compressed).length;
      if (candidateLength >= decompressed.length) return null;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static Uint8List compressBytes(Uint8List input) {
    final out = BytesBuilder(copy: false);
    final verbatim = <int>[];
    int index = 0;

    void flushVerbatim() {
      if (verbatim.isEmpty) return;
      if (verbatim.length == 1) {
        out.addByte(_verbatimSingle);
        out.addByte(verbatim[0]);
      } else {
        out.addByte(_verbatimRun);
        out.addByte(verbatim.length - 1);
        out.add(verbatim);
      }
      verbatim.clear();
    }

    while (index < input.length) {
      int bestLen = 0;
      int bestCode = -1;
      final remaining = input.length - index;
      final maxLen = remaining < _maxEntryLen ? remaining : _maxEntryLen;

      for (int code = 0; code < _rcbBytes.length; code++) {
        final entry = _rcbBytes[code];
        final entryLen = entry.length;
        if (entryLen == 0 || entryLen > maxLen || entryLen <= bestLen) {
          continue;
        }
        if (_matches(input, index, entry)) {
          bestLen = entryLen;
          bestCode = code;
          if (bestLen == maxLen) {
            break;
          }
        }
      }

      if (bestCode >= 0) {
        flushVerbatim();
        out.addByte(bestCode);
        index += bestLen;
        continue;
      }

      verbatim.add(input[index]);
      index++;
      if (verbatim.length == 256) {
        flushVerbatim();
      }
    }

    flushVerbatim();
    return out.toBytes();
  }

  static Uint8List decompressBytes(Uint8List input) {
    final out = BytesBuilder(copy: false);
    int index = 0;

    while (index < input.length) {
      final code = input[index];
      if (code == _verbatimSingle) {
        if (index + 1 >= input.length) {
          throw const FormatException(
            'Invalid SMAZ stream: truncated verbatim byte.',
          );
        }
        out.addByte(input[index + 1]);
        index += 2;
      } else if (code == _verbatimRun) {
        if (index + 1 >= input.length) {
          throw const FormatException(
            'Invalid SMAZ stream: truncated verbatim length.',
          );
        }
        final len = input[index + 1] + 1;
        final end = index + 2 + len;
        if (end > input.length) {
          throw const FormatException(
            'Invalid SMAZ stream: truncated verbatim run.',
          );
        }
        out.add(input.sublist(index + 2, end));
        index = end;
      } else {
        if (code >= _rcbBytes.length) {
          throw const FormatException(
            'Invalid SMAZ stream: code out of range.',
          );
        }
        out.add(_rcbBytes[code]);
        index += 1;
      }
    }

    return out.toBytes();
  }

  static bool _matches(Uint8List input, int offset, Uint8List entry) {
    final len = entry.length;
    if (offset + len > input.length) return false;
    for (int i = 0; i < len; i++) {
      if (input[offset + i] != entry[i]) return false;
    }
    return true;
  }

  static Uint8List _decodeBase64Flexible(String encoded) {
    final trimmed = encoded.trim();
    try {
      return base64Decode(trimmed);
    } catch (_) {
      // Try base64url with missing padding.
      var normalized = trimmed.replaceAll('-', '+').replaceAll('_', '/');
      final pad = normalized.length % 4;
      if (pad != 0) {
        normalized = normalized.padRight(normalized.length + (4 - pad), '=');
      }
      return base64Decode(normalized);
    }
  }
}
