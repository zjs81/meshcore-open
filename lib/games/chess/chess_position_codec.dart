import 'dart:typed_data';

/// Packs a chess position into at most [maxBytes] bytes and back.
///
/// Layout:
/// * 8 bytes: occupancy bitboard, bit `i` = square `i` (a1 = 0 … h8 = 63),
///   byte `i >> 3`, bit `i & 7`.
/// * 2 bytes (LE): bit 0 black to move, bits 1–4 castling K Q k q,
///   bits 5–8 en-passant file + 1 (0 = none), bits 9–15 halfmove clock
///   (capped at 127).
/// * One nibble per occupied square in square order, high nibble first:
///   bit 3 black, bits 0–2 piece (pawn 0, knight 1, bishop 2, rook 3,
///   queen 4, king 5). Padded with a zero nibble to a whole byte.
///
/// The full-move number is not packed; it follows from the game's ply.
abstract final class ChessPositionCodec {
  static const int maxBytes = 26;
  static const int _fixedBytes = 10;
  static const String _pieces = 'pnbrqk';

  /// Packs the first four FEN fields plus the halfmove clock of [fen].
  /// Throws [FormatException] for a malformed FEN.
  static Uint8List encodeFen(String fen) {
    final fields = fen.trim().split(RegExp(r'\s+'));
    if (fields.length < 4) throw FormatException('Bad FEN', fen);
    final ranks = fields[0].split('/');
    if (ranks.length != 8) throw FormatException('Bad FEN board', fen);

    final occupancy = Uint8List(8);
    final nibbles = <int>[];
    final squares = List<int?>.filled(64, null);
    for (var r = 0; r < 8; r++) {
      final rank = 7 - r; // FEN lists rank 8 first.
      var file = 0;
      for (final ch in ranks[r].split('')) {
        final digit = int.tryParse(ch);
        if (digit != null) {
          file += digit;
          continue;
        }
        final type = _pieces.indexOf(ch.toLowerCase());
        if (type < 0 || file > 7) throw FormatException('Bad piece', fen);
        final black = ch == ch.toLowerCase();
        squares[rank * 8 + file] = (black ? 8 : 0) | type;
        file++;
      }
      if (file != 8) throw FormatException('Bad rank', fen);
    }
    for (var sq = 0; sq < 64; sq++) {
      final piece = squares[sq];
      if (piece == null) continue;
      occupancy[sq >> 3] |= 1 << (sq & 7);
      nibbles.add(piece);
    }
    if (nibbles.length > 32) throw FormatException('Too many pieces', fen);

    var state = fields[1] == 'b' ? 1 : 0;
    final castling = fields[2];
    if (castling.contains('K')) state |= 1 << 1;
    if (castling.contains('Q')) state |= 1 << 2;
    if (castling.contains('k')) state |= 1 << 3;
    if (castling.contains('q')) state |= 1 << 4;
    final ep = fields[3];
    if (ep != '-') {
      final file = ep.codeUnitAt(0) - 'a'.codeUnitAt(0);
      if (file < 0 || file > 7) throw FormatException('Bad en passant', fen);
      state |= (file + 1) << 5;
    }
    final halfmove = fields.length > 4 ? int.tryParse(fields[4]) ?? 0 : 0;
    state |= (halfmove.clamp(0, 127)) << 9;

    final out = BytesBuilder()
      ..add(occupancy)
      ..addByte(state & 0xFF)
      ..addByte((state >> 8) & 0xFF);
    for (var i = 0; i < nibbles.length; i += 2) {
      final hi = nibbles[i];
      final lo = i + 1 < nibbles.length ? nibbles[i + 1] : 0;
      out.addByte((hi << 4) | lo);
    }
    return out.toBytes();
  }

  /// Unpacks [bytes] into a FEN with [fullMoveNumber]. Returns null when the
  /// bytes are malformed (wrong length for the occupancy, bad piece codes).
  /// Castling and en-passant rights that the pieces rule out are dropped;
  /// otherwise the position is not checked for legality.
  static String? decodeToFen(Uint8List bytes, {required int fullMoveNumber}) {
    if (bytes.length < _fixedBytes) return null;
    final squares = <int>[];
    for (var sq = 0; sq < 64; sq++) {
      if (bytes[sq >> 3] & (1 << (sq & 7)) != 0) squares.add(sq);
    }
    if (squares.length > 32) return null;
    if (bytes.length != _fixedBytes + (squares.length + 1) ~/ 2) return null;

    final board = List<String?>.filled(64, null);
    for (var i = 0; i < squares.length; i++) {
      final byte = bytes[_fixedBytes + (i >> 1)];
      final nibble = i.isEven ? byte >> 4 : byte & 0x0F;
      final type = nibble & 0x07;
      if (type > 5) return null;
      final letter = _pieces[type];
      board[squares[i]] = nibble & 0x08 != 0 ? letter : letter.toUpperCase();
    }

    final rows = <String>[];
    for (var rank = 7; rank >= 0; rank--) {
      final row = StringBuffer();
      var empty = 0;
      for (var file = 0; file < 8; file++) {
        final p = board[rank * 8 + file];
        if (p == null) {
          empty++;
          continue;
        }
        if (empty > 0) row.write(empty);
        empty = 0;
        row.write(p);
      }
      if (empty > 0) row.write(empty);
      rows.add(row.toString());
    }

    final state = bytes[8] | (bytes[9] << 8);
    final blackToMove = state & 1 != 0;
    // Square indices: a1 = 0, e1 = 4, h1 = 7, a8 = 56, e8 = 60, h8 = 63.
    final castling = StringBuffer();
    if (state & (1 << 1) != 0 && board[4] == 'K' && board[7] == 'R') {
      castling.write('K');
    }
    if (state & (1 << 2) != 0 && board[4] == 'K' && board[0] == 'R') {
      castling.write('Q');
    }
    if (state & (1 << 3) != 0 && board[60] == 'k' && board[63] == 'r') {
      castling.write('k');
    }
    if (state & (1 << 4) != 0 && board[60] == 'k' && board[56] == 'r') {
      castling.write('q');
    }
    final epFile = (state >> 5) & 0x0F;
    if (epFile > 8) return null;
    var ep = '-';
    if (epFile != 0) {
      final file = epFile - 1;
      // The pawn that just moved two squares, and the two squares it passed.
      final pawnSq = (blackToMove ? 3 : 4) * 8 + file;
      final passed = (blackToMove ? 2 : 5) * 8 + file;
      final start = (blackToMove ? 1 : 6) * 8 + file;
      if (board[pawnSq] == (blackToMove ? 'P' : 'p') &&
          board[passed] == null &&
          board[start] == null) {
        ep =
            '${String.fromCharCode('a'.codeUnitAt(0) + file)}'
            '${blackToMove ? 3 : 6}';
      }
    }
    final halfmove = (state >> 9) & 0x7F;

    return '${rows.join('/')} ${blackToMove ? 'b' : 'w'} '
        '${castling.isEmpty ? '-' : castling} $ep $halfmove '
        '${fullMoveNumber < 1 ? 1 : fullMoveNumber}';
  }
}
