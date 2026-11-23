import 'dart:math';
import 'dart:typed_data';

import 'package:chess/chess.dart' as rules;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/games/chess/chess_game.dart';
import 'package:meshcore_open/games/chess/chess_packets.dart';
import 'package:meshcore_open/games/chess/chess_position_codec.dart';
import 'package:meshcore_open/games/game_packet.dart';
import 'package:meshcore_open/games/hash_chain.dart';

Uint8List _bytes(int n, int seed) =>
    Uint8List.fromList(List.generate(n, (i) => (i * 31 + seed) & 0xFF));

/// FEN without the full-move number, which the codec does not carry.
String _withoutMoveNumber(String fen) => fen.split(' ').sublist(0, 5).join(' ');

void main() {
  group('position codec', () {
    test('start position packs to 26 bytes and round-trips', () {
      final packed = ChessPositionCodec.encodeFen(ChessGame.startFen);
      expect(packed.length, 26);
      expect(
        ChessPositionCodec.decodeToFen(packed, fullMoveNumber: 1),
        ChessGame.startFen,
      );
    });

    test('round-trips positions from random games', () {
      final rng = Random(7);
      var positions = 0;
      for (var game = 0; game < 40; game++) {
        final board = rules.Chess();
        for (var ply = 0; ply < 120 && !board.game_over; ply++) {
          final moves = board.moves({'asObjects': true}).cast<rules.Move>();
          board.move(moves[rng.nextInt(moves.length)]);
          final fen = board.fen;
          final packed = ChessPositionCodec.encodeFen(fen);
          expect(packed.length, lessThanOrEqualTo(ChessPositionCodec.maxBytes));
          final decoded = ChessPositionCodec.decodeToFen(
            packed,
            fullMoveNumber: board.move_number,
          );
          expect(
            _withoutMoveNumber(decoded!),
            _withoutMoveNumber(fen),
            reason: fen,
          );
          positions++;
        }
      }
      expect(positions, greaterThan(1000));
    });

    test('drops castling and en passant rights the pieces rule out', () {
      // Kings on e1/e8 but the h1 rook gone; an en passant file with no pawn.
      const fen = 'r3k2r/8/8/8/8/8/8/R3K3 w KQkq e6 0 1';
      final packed = ChessPositionCodec.encodeFen(fen);
      final decoded = ChessPositionCodec.decodeToFen(packed, fullMoveNumber: 1);
      expect(decoded, 'r3k2r/8/8/8/8/8/8/R3K3 w Qkq - 0 1');
      // The rules engine can list moves for it without throwing.
      final game = ChessGame(
        channelId: 'c',
        gameId: 1,
        status: ChessGameStatus.active,
        deadline: ChessDeadline.none,
        createdAtMs: 0,
      )..adoptPosition(decoded!, 0);
      expect(game.legalUci(), contains('e1c1'));
      expect(game.legalUci(), isNot(contains('e1g1')));

      // A real en passant chance survives.
      const ep =
          'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3';
      expect(
        ChessPositionCodec.decodeToFen(
          ChessPositionCodec.encodeFen(ep),
          fullMoveNumber: 3,
        ),
        ep,
      );
    });

    test('rejects a length that does not match the occupancy', () {
      final packed = ChessPositionCodec.encodeFen(ChessGame.startFen);
      expect(
        ChessPositionCodec.decodeToFen(
          Uint8List.fromList(packed.sublist(0, 20)),
          fullMoveNumber: 1,
        ),
        isNull,
      );
    });
  });

  group('hash chain', () {
    final chain = HashChain(_bytes(16, 3));

    test('each value hashes to the previous one', () {
      expect(hashChainStep(chain.valueAt(1)), chain.valueAt(0));
      expect(hashChainStep(chain.valueAt(10)), chain.valueAt(9));
    });

    test('distance counts skipped values and flags duplicates', () {
      expect(hashChainDistance(chain.valueAt(1), chain.commitment), 1);
      expect(hashChainDistance(chain.valueAt(5), chain.valueAt(2)), 3);
      expect(hashChainDistance(chain.valueAt(2), chain.valueAt(2)), 0);
    });

    test('rejects older values and other chains', () {
      expect(hashChainDistance(chain.valueAt(2), chain.valueAt(5)), isNull);
      final other = HashChain(_bytes(16, 9));
      expect(hashChainDistance(other.valueAt(1), chain.commitment), isNull);
    });

    test('player values count once and only in order', () {
      final player = ChessPlayer(name: 'A', commitment: chain.commitment);
      expect(player.freshIndex(chain.valueAt(1)), 1);
      player.use(1);
      expect(player.freshIndex(chain.valueAt(1)), isNull);
      expect(player.freshIndex(chain.valueAt(4)), 4);
      player.use(4);
      // Index 3 was never used, but anyone can compute it from value 4.
      expect(player.freshIndex(chain.valueAt(3)), isNull);
      expect(player.lastIndex, 4);
    });

    test('the inviter chain keeps value 1 for the game info', () {
      final inviter = ChessPlayer.inviter(
        name: 'A',
        commitment: chain.commitment,
      );
      expect(inviter.freshIndex(chain.valueAt(1)), isNull);
      expect(inviter.freshIndex(chain.valueAt(2)), 2);
    });
  });

  group('packets', () {
    final commitment = _bytes(16, 1);
    final value = _bytes(16, 2);
    final longName = 'N' * 40;

    test('move packet fits one 64-byte encrypted block run', () {
      final packet = ChessMovePacket(
        gameId: 0xBEEF,
        ply: 300,
        moveIndex: 17,
        chainValue: value,
        position: ChessPositionCodec.encodeFen(ChessGame.startFen),
      );
      final bytes = packet.encode();
      expect(bytes.length, 48);
      expect(encryptedGamePayloadSize(bytes.length), 64);
      final decoded = ChessPacket.decode(bytes) as ChessMovePacket;
      expect(decoded.gameId, 0xBEEF);
      expect(decoded.ply, 300);
      expect(decoded.moveIndex, 17);
      expect(decoded.chainValue, value);
      expect(decoded.position, packet.position);
    });

    test('invite sizes and names are capped', () {
      final open = ChessInvitePacket(
        gameId: 1,
        deadline: ChessDeadline.hour1,
        colour: ChessColourPreference.black,
        commitment: commitment,
        inviterName: longName,
      ).encode();
      expect(open.length, 55);
      expect(encryptedGamePayloadSize(open.length), 64);
      final direct = ChessInvitePacket(
        gameId: 1,
        deadline: ChessDeadline.days3,
        colour: ChessColourPreference.random,
        commitment: commitment,
        inviterName: longName,
        targetName: longName,
      );
      final bytes = direct.encode();
      expect(bytes.length, 87);
      final decoded = ChessPacket.decode(bytes) as ChessInvitePacket;
      expect(decoded.inviterName, 'N' * maxGameNameBytes);
      expect(decoded.targetName, 'N' * maxGameNameBytes);
      expect(decoded.deadline, ChessDeadline.days3);
      expect(decoded.isDirect, isTrue);
      final accept = ChessAcceptPacket(
        gameId: 1,
        commitment: commitment,
        accepterName: longName,
      ).encode();
      expect(accept.length, 53);
      final decline = ChessDeclinePacket(
        gameId: 1,
        declinerName: longName,
      ).encode();
      expect(decline.length, 37);
    });

    test('names are cut on a character boundary', () {
      final name = '${'a' * 29}é'; // 29 + 2 bytes = 31: fits.
      expect(truncateUtf8(name, 31).length, 31);
      expect(truncateUtf8('${'a' * 30}é', 31).length, 30);
    });

    test('actions, info and requests round-trip', () {
      final action = ChessActionPacket(
        kind: ChessPacketKind.resign,
        gameId: 9,
        ply: 4,
        chainValue: value,
      ).encode();
      expect(action.length, 21);
      expect(encryptedGamePayloadSize(action.length), 32);
      expect(
        (ChessPacket.decode(action) as ChessActionPacket).kind,
        ChessPacketKind.resign,
      );

      final info = ChessInfoPacket(
        gameId: 9,
        ply: 4,
        startedAtUnix: 1700000000,
        deadline: ChessDeadline.hour1,
        whiteCommitment: commitment,
        blackCommitment: value,
        inviterValue: value,
        whiteName: longName,
        blackName: longName,
      ).encode();
      expect(info.length, 122);
      expect(info.length, lessThanOrEqualTo(maxGamePayloadBytes));
      final decodedInfo = ChessPacket.decode(info) as ChessInfoPacket;
      expect(decodedInfo.startedAtUnix, 1700000000);
      expect(decodedInfo.blackCommitment, value);
      expect(decodedInfo.inviterValue, value);

      final request = ChessRequestPacket(
        gameId: 9,
        ply: 4,
        wantsInfo: true,
        wantsLatestMove: true,
      ).encode();
      expect(request.length, 6);
      final decodedRequest = ChessPacket.decode(request) as ChessRequestPacket;
      expect(decodedRequest.wantsInfo, isTrue);
      expect(decodedRequest.wantsLatestMove, isTrue);
    });

    test('rejects other apps and truncated packets', () {
      final bytes = ChessAcceptPacket(
        gameId: 2,
        commitment: commitment,
        accepterName: 'Bob',
      ).encode();
      expect(ChessPacket.decode(bytes.sublist(0, 10)), isNull);
      final otherApp = Uint8List.fromList(bytes)..[0] = 0x21;
      expect(ChessPacket.decode(otherApp), isNull);
    });
  });
}
