import 'dart:typed_data';

import '../game_packet.dart';
import '../hash_chain.dart';

/// Packet kinds of chess v1 (the low nibble of the first payload byte).
enum ChessPacketKind {
  invite(0),
  accept(1),
  decline(2),
  move(3),
  resign(4),
  drawOffer(5),
  drawAccept(6),
  cancel(7),
  timeoutClaim(8),
  info(9),
  request(10);

  final int code;
  const ChessPacketKind(this.code);

  static ChessPacketKind? fromCode(int code) {
    for (final k in values) {
      if (k.code == code) return k;
    }
    return null;
  }
}

/// Colour the inviter wants to play.
enum ChessColourPreference {
  random(0),
  white(1),
  black(2);

  final int code;
  const ChessColourPreference(this.code);

  static ChessColourPreference fromCode(int code) =>
      values.firstWhere((v) => v.code == code, orElse: () => random);
}

/// Per-move deadline choices, carried as one byte.
enum ChessDeadline {
  none(0, null),
  min15(1, Duration(minutes: 15)),
  hour1(2, Duration(hours: 1)),
  hours6(3, Duration(hours: 6)),
  day1(4, Duration(days: 1)),
  days3(5, Duration(days: 3));

  final int code;
  final Duration? duration;
  const ChessDeadline(this.code, this.duration);

  static const ChessDeadline defaultValue = hour1;

  static ChessDeadline fromCode(int code) =>
      values.firstWhere((v) => v.code == code, orElse: () => defaultValue);
}

/// A decoded chess packet. [ply] is the half-move number modulo 256.
sealed class ChessPacket {
  final int gameId;
  final int ply;

  const ChessPacket({required this.gameId, required this.ply});

  ChessPacketKind get kind;

  Uint8List encode() {
    final out = BytesBuilder();
    GamePacketHeader(
      app: GameApp.chess,
      kind: kind.code,
      gameId: gameId,
      ply: ply,
    ).writeTo(out);
    writeBody(out);
    return out.toBytes();
  }

  void writeBody(BytesBuilder out);

  /// Decodes a chess payload, or null when it is not one or is malformed.
  static ChessPacket? decode(Uint8List payload) {
    final header = GamePacketHeader.parse(payload);
    if (header == null || header.app != GameApp.chess) return null;
    final kind = ChessPacketKind.fromCode(header.kind);
    if (kind == null) return null;
    final r = GamePacketReader(payload, GamePacketHeader.length);
    final id = header.gameId;
    final ply = header.ply;
    final ChessPacket? packet = switch (kind) {
      ChessPacketKind.invite => ChessInvitePacket._read(id, ply, r),
      ChessPacketKind.accept => ChessAcceptPacket._read(id, ply, r),
      ChessPacketKind.decline => ChessDeclinePacket._read(id, ply, r),
      ChessPacketKind.move => ChessMovePacket._read(id, ply, r),
      ChessPacketKind.resign ||
      ChessPacketKind.drawOffer ||
      ChessPacketKind.drawAccept ||
      ChessPacketKind.cancel ||
      ChessPacketKind.timeoutClaim => ChessActionPacket._read(kind, id, ply, r),
      ChessPacketKind.info => ChessInfoPacket._read(id, ply, r),
      ChessPacketKind.request => ChessRequestPacket._read(id, ply, r),
    };
    if (packet == null || r.failed) return null;
    return packet;
  }
}

/// Open invite, or a direct challenge when [targetName] is set.
class ChessInvitePacket extends ChessPacket {
  final ChessDeadline deadline;
  final ChessColourPreference colour;
  final Uint8List commitment;
  final String inviterName;
  final String? targetName;

  const ChessInvitePacket({
    required super.gameId,
    required this.deadline,
    required this.colour,
    required this.commitment,
    required this.inviterName,
    this.targetName,
  }) : super(ply: 0);

  bool get isDirect => targetName != null;

  @override
  ChessPacketKind get kind => ChessPacketKind.invite;

  @override
  void writeBody(BytesBuilder out) {
    out
      ..addByte(deadline.code)
      ..addByte(colour.code | (isDirect ? 0x04 : 0))
      ..add(commitment);
    writeShortString(out, inviterName);
    if (targetName != null) writeShortString(out, targetName!);
  }

  static ChessInvitePacket? _read(int id, int ply, GamePacketReader r) {
    final deadline = r.u8();
    final flags = r.u8();
    final commitment = r.bytes(HashChain.valueBytes);
    final name = r.shortString();
    if (deadline == null || flags == null || commitment == null) return null;
    if (name == null) return null;
    String? target;
    if (flags & 0x04 != 0) {
      target = r.shortString();
      if (target == null) return null;
    }
    return ChessInvitePacket(
      gameId: id,
      deadline: ChessDeadline.fromCode(deadline),
      colour: ChessColourPreference.fromCode(flags & 0x03),
      commitment: commitment,
      inviterName: name,
      targetName: target,
    );
  }
}

class ChessAcceptPacket extends ChessPacket {
  final Uint8List commitment;
  final String accepterName;

  const ChessAcceptPacket({
    required super.gameId,
    required this.commitment,
    required this.accepterName,
  }) : super(ply: 0);

  @override
  ChessPacketKind get kind => ChessPacketKind.accept;

  @override
  void writeBody(BytesBuilder out) {
    out.add(commitment);
    writeShortString(out, accepterName);
  }

  static ChessAcceptPacket? _read(int id, int ply, GamePacketReader r) {
    final commitment = r.bytes(HashChain.valueBytes);
    final name = r.shortString();
    if (commitment == null || name == null) return null;
    return ChessAcceptPacket(
      gameId: id,
      commitment: commitment,
      accepterName: name,
    );
  }
}

/// A declined direct challenge. Not authenticated; only the inviter acts on
/// it, and only for a challenge addressed to [declinerName].
class ChessDeclinePacket extends ChessPacket {
  final String declinerName;

  const ChessDeclinePacket({required super.gameId, required this.declinerName})
    : super(ply: 0);

  @override
  ChessPacketKind get kind => ChessPacketKind.decline;

  @override
  void writeBody(BytesBuilder out) => writeShortString(out, declinerName);

  static ChessDeclinePacket? _read(int id, int ply, GamePacketReader r) {
    final name = r.shortString();
    if (name == null) return null;
    return ChessDeclinePacket(gameId: id, declinerName: name);
  }
}

/// One half-move. [ply] is the number of the half-move being made (the first
/// move of the game has ply 1). [position] is the packed position after it.
class ChessMovePacket extends ChessPacket {
  final int minutes;
  final int moveIndex;
  final Uint8List chainValue;
  final Uint8List position;

  const ChessMovePacket({
    required super.gameId,
    required super.ply,
    required this.minutes,
    required this.moveIndex,
    required this.chainValue,
    required this.position,
  });

  @override
  ChessPacketKind get kind => ChessPacketKind.move;

  @override
  void writeBody(BytesBuilder out) {
    writeU16(out, minutes);
    out
      ..addByte(moveIndex)
      ..add(chainValue)
      ..add(position);
  }

  static ChessMovePacket? _read(int id, int ply, GamePacketReader r) {
    final minutes = r.u16();
    final index = r.u8();
    final chain = r.bytes(HashChain.valueBytes);
    final position = r.rest();
    if (minutes == null || index == null || chain == null) return null;
    if (position == null || position.isEmpty) return null;
    return ChessMovePacket(
      gameId: id,
      ply: ply,
      minutes: minutes,
      moveIndex: index,
      chainValue: chain,
      position: position,
    );
  }
}

/// Resign, draw offer, draw accept, cancel invite or timeout claim: an
/// authenticated action with no other data.
class ChessActionPacket extends ChessPacket {
  @override
  final ChessPacketKind kind;
  final int minutes;
  final Uint8List chainValue;

  const ChessActionPacket({
    required this.kind,
    required super.gameId,
    required super.ply,
    required this.minutes,
    required this.chainValue,
  });

  @override
  void writeBody(BytesBuilder out) {
    writeU16(out, minutes);
    out.add(chainValue);
  }

  static ChessActionPacket? _read(
    ChessPacketKind kind,
    int id,
    int ply,
    GamePacketReader r,
  ) {
    final minutes = r.u16();
    final chain = r.bytes(HashChain.valueBytes);
    if (minutes == null || chain == null) return null;
    return ChessActionPacket(
      kind: kind,
      gameId: id,
      ply: ply,
      minutes: minutes,
      chainValue: chain,
    );
  }
}

/// Everything a late spectator needs to follow and verify a game.
class ChessInfoPacket extends ChessPacket {
  final int startedAtUnix;
  final ChessDeadline deadline;
  final Uint8List whiteCommitment;
  final Uint8List blackCommitment;
  final String whiteName;
  final String blackName;

  const ChessInfoPacket({
    required super.gameId,
    required super.ply,
    required this.startedAtUnix,
    required this.deadline,
    required this.whiteCommitment,
    required this.blackCommitment,
    required this.whiteName,
    required this.blackName,
  });

  @override
  ChessPacketKind get kind => ChessPacketKind.info;

  @override
  void writeBody(BytesBuilder out) {
    writeU32(out, startedAtUnix);
    out
      ..addByte(deadline.code)
      ..addByte(0) // flags, reserved
      ..add(whiteCommitment)
      ..add(blackCommitment);
    writeShortString(out, whiteName);
    writeShortString(out, blackName);
  }

  static ChessInfoPacket? _read(int id, int ply, GamePacketReader r) {
    final started = r.u32();
    final deadline = r.u8();
    r.u8(); // flags
    final white = r.bytes(HashChain.valueBytes);
    final black = r.bytes(HashChain.valueBytes);
    final whiteName = r.shortString();
    final blackName = r.shortString();
    if (started == null || deadline == null || white == null) return null;
    if (black == null || whiteName == null || blackName == null) return null;
    return ChessInfoPacket(
      gameId: id,
      ply: ply,
      startedAtUnix: started,
      deadline: ChessDeadline.fromCode(deadline),
      whiteCommitment: white,
      blackCommitment: black,
      whiteName: whiteName,
      blackName: blackName,
    );
  }
}

/// Asks the players for the game info and/or the latest move. [ply] is the
/// last half-move the requester has.
class ChessRequestPacket extends ChessPacket {
  final bool wantsInfo;
  final bool wantsLatestMove;

  const ChessRequestPacket({
    required super.gameId,
    required super.ply,
    this.wantsInfo = false,
    this.wantsLatestMove = false,
  });

  @override
  ChessPacketKind get kind => ChessPacketKind.request;

  @override
  void writeBody(BytesBuilder out) =>
      out.addByte((wantsInfo ? 1 : 0) | (wantsLatestMove ? 2 : 0));

  static ChessRequestPacket? _read(int id, int ply, GamePacketReader r) {
    final flags = r.u8();
    if (flags == null) return null;
    return ChessRequestPacket(
      gameId: id,
      ply: ply,
      wantsInfo: flags & 1 != 0,
      wantsLatestMove: flags & 2 != 0,
    );
  }
}
