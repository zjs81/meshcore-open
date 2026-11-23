import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../widgets/mesh_nav_tile.dart';
import '../../../widgets/mesh_ui.dart';

/// Board square colours. The board is content, not chrome, so it keeps the
/// same classic colours in every theme; both have strong contrast with the
/// white and black pieces.
abstract final class ChessBoardPalette {
  static const Color light = Color(0xFFEEEED2);
  static const Color dark = Color(0xFF769656);
  static const Color lastMove = Color(0x99F6E05E);
  static const Color check = Color(0xCCE53935);
  static const Color hint = Color(0x8C1B1B1B);
}

/// A chess piece drawn from vectors. [piece] is a FEN letter (`K`, `q`, …).
Widget chessPieceWidget(String piece, double size) {
  return switch (piece) {
    'P' => WhitePawn(size: size),
    'N' => WhiteKnight(size: size),
    'B' => WhiteBishop(size: size),
    'R' => WhiteRook(size: size),
    'Q' => WhiteQueen(size: size),
    'K' => WhiteKing(size: size),
    'p' => BlackPawn(size: size),
    'n' => BlackKnight(size: size),
    'b' => BlackBishop(size: size),
    'r' => BlackRook(size: size),
    'q' => BlackQueen(size: size),
    'k' => BlackKing(size: size),
    _ => SizedBox(width: size, height: size),
  };
}

/// Pieces by square (`e4` → `P`) from the board field of [fen].
Map<String, String> piecesFromFen(String fen) {
  final out = <String, String>{};
  final rows = fen.split(' ').first.split('/');
  for (var r = 0; r < rows.length && r < 8; r++) {
    final rank = 8 - r;
    var file = 0;
    for (final ch in rows[r].split('')) {
      final n = int.tryParse(ch);
      if (n != null) {
        file += n;
        continue;
      }
      if (file < 8) {
        out['${String.fromCharCode(97 + file)}$rank'] = ch;
      }
      file++;
    }
  }
  return out;
}

/// An 8×8 board. Tap one of your pieces, then a highlighted square, to
/// move. [legalMoves] (UCI) enables input; pass an empty list for a
/// read-only board.
class ChessBoardView extends StatefulWidget {
  final String fen;
  final bool flipped;
  final String? lastMoveUci;
  final bool inCheck;
  final List<String> legalMoves;
  final ValueChanged<String>? onMove;

  const ChessBoardView({
    super.key,
    required this.fen,
    this.flipped = false,
    this.lastMoveUci,
    this.inCheck = false,
    this.legalMoves = const [],
    this.onMove,
  });

  @override
  State<ChessBoardView> createState() => _ChessBoardViewState();
}

class _ChessBoardViewState extends State<ChessBoardView> {
  String? _selected;

  @override
  void didUpdateWidget(ChessBoardView old) {
    super.didUpdateWidget(old);
    if (old.fen != widget.fen) _selected = null;
  }

  bool get _interactive =>
      widget.onMove != null && widget.legalMoves.isNotEmpty;

  Iterable<String> _movesFrom(String square) =>
      widget.legalMoves.where((m) => m.startsWith(square));

  Future<void> _onTap(String square) async {
    if (!_interactive) return;
    final selected = _selected;
    if (selected != null) {
      final moves = _movesFrom(
        selected,
      ).where((m) => m.substring(2, 4) == square).toList();
      if (moves.isNotEmpty) {
        setState(() => _selected = null);
        var uci = moves.first;
        if (moves.length > 1) {
          final promotion = await _pickPromotion(moves);
          if (promotion == null) return;
          uci = promotion;
        }
        widget.onMove?.call(uci);
        return;
      }
    }
    setState(() {
      _selected = _movesFrom(square).isNotEmpty && selected != square
          ? square
          : null;
    });
  }

  Future<String?> _pickPromotion(List<String> moves) {
    final l10n = context.l10n;
    final labels = {
      'q': l10n.chess_pieceQueen,
      'r': l10n.chess_pieceRook,
      'b': l10n.chess_pieceBishop,
      'n': l10n.chess_pieceKnight,
    };
    return showMeshSheet<String>(
      context,
      builder: (sheetContext) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomSheetHeader(title: l10n.chess_promoteTitle),
            for (final letter in const ['q', 'r', 'b', 'n'])
              for (final m in moves.where((m) => m.endsWith(letter)))
                MeshSheetOption(
                  label: labels[letter]!,
                  selected: false,
                  onTap: () => Navigator.pop(sheetContext, m),
                ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pieces = piecesFromFen(widget.fen);
    final last = widget.lastMoveUci;
    final lastSquares = last == null || last.length < 4
        ? const <String>{}
        : {last.substring(0, 2), last.substring(2, 4)};
    final targets = _selected == null
        ? const <String>{}
        : _movesFrom(_selected!).map((m) => m.substring(2, 4)).toSet();
    final whiteToMove = widget.fen.split(' ').elementAtOrNull(1) != 'b';
    final checkedKing = widget.inCheck ? (whiteToMove ? 'K' : 'k') : null;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / 8;
          return Column(
            children: [
              for (var row = 0; row < 8; row++)
                Row(
                  children: [
                    for (var col = 0; col < 8; col++)
                      _square(
                        context,
                        scheme: scheme,
                        cell: cell,
                        row: row,
                        col: col,
                        pieces: pieces,
                        lastSquares: lastSquares,
                        targets: targets,
                        checkedKing: checkedKing,
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _square(
    BuildContext context, {
    required ColorScheme scheme,
    required double cell,
    required int row,
    required int col,
    required Map<String, String> pieces,
    required Set<String> lastSquares,
    required Set<String> targets,
    required String? checkedKing,
  }) {
    final file = widget.flipped ? 7 - col : col;
    final rank = widget.flipped ? row + 1 : 8 - row;
    final square = '${String.fromCharCode(97 + file)}$rank';
    final isLight = (file + rank).isOdd;
    final piece = pieces[square];
    final isTarget = targets.contains(square);
    final isSelected = _selected == square;
    final coordStyle = TextStyle(
      fontSize: (cell * 0.24).clamp(12.0, 14.0),
      fontWeight: FontWeight.w700,
      color: isLight ? ChessBoardPalette.dark : ChessBoardPalette.light,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(square),
      child: Semantics(
        label: piece == null ? square : '$square $piece',
        button: isTarget || (_interactive && piece != null),
        selected: isSelected,
        child: SizedBox(
          width: cell,
          height: cell,
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: isLight
                      ? ChessBoardPalette.light
                      : ChessBoardPalette.dark,
                ),
              ),
              if (lastSquares.contains(square))
                const Positioned.fill(
                  child: ColoredBox(color: ChessBoardPalette.lastMove),
                ),
              if (piece != null && piece == checkedKing)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          ChessBoardPalette.check,
                          ChessBoardPalette.check.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              if (isSelected)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.primary, width: 3),
                    ),
                  ),
                ),
              if (col == 0)
                Positioned(
                  left: 2,
                  top: 1,
                  child: Text('$rank', style: coordStyle),
                ),
              if (row == 7)
                Positioned(
                  right: 2,
                  bottom: 0,
                  child: Text(
                    String.fromCharCode(97 + file),
                    style: coordStyle,
                  ),
                ),
              if (piece != null)
                Center(child: chessPieceWidget(piece, cell * 0.92)),
              if (isTarget)
                Center(
                  child: piece == null
                      ? Container(
                          width: cell * 0.3,
                          height: cell * 0.3,
                          decoration: const BoxDecoration(
                            color: ChessBoardPalette.hint,
                            shape: BoxShape.circle,
                          ),
                        )
                      : Container(
                          width: cell * 0.92,
                          height: cell * 0.92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ChessBoardPalette.hint,
                              width: cell * 0.08,
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
