import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

import '../../connector/meshcore_connector.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/locale_tag.dart';
import '../../services/app_settings_service.dart';
import '../../services/image_chunk_transport.dart';
import '../../services/notification_reply.dart';
import '../../services/notification_service.dart';
import '../../storage/prefs_manager.dart';
import '../game_packet.dart';

/// A game payload heard on a channel.
class ChessIncoming {
  final String channelId;
  final Uint8List payload;

  const ChessIncoming(this.channelId, this.payload);
}

/// What the chess service needs from the radio. [ConnectorChessLink] is the
/// app's implementation; tests use an in-memory one.
abstract class ChessLink implements Listenable {
  Stream<ChessIncoming> get incoming;

  /// Sends [payload] on the channel with storage id [channelId].
  Future<bool> send(String channelId, Uint8List payload);

  /// Our advert name.
  String get selfName;

  /// Per-radio storage scope (10 hex chars), or '' when unknown.
  String get storageScope;

  bool get canSend;

  /// Shows a notification for a game event on [channelId], honouring the
  /// channel's notification mode.
  void notify(String channelId, String text);

  /// Localized strings for notification text.
  AppLocalizations get l10n;
}

/// [ChessLink] over [MeshCoreConnector]. Listens to the public frame stream
/// for GRP_DATA with [meshcoreOpenDataType] and sends with
/// [MeshCoreConnector.sendChannelData]; nothing else in the connector is
/// involved.
class ConnectorChessLink extends ChangeNotifier implements ChessLink {
  static const int _maxBuffered = 64;

  final MeshCoreConnector connector;
  final AppSettingsService? settings;
  final StreamController<ChessIncoming> _incoming =
      StreamController<ChessIncoming>.broadcast();
  final List<ParsedChannelData> _awaitingMap = [];
  StreamSubscription<Uint8List>? _frames;
  String _lastScope = '';
  String _lastName = '';
  bool _lastCanSend = false;

  ConnectorChessLink(this.connector, {this.settings}) {
    _frames = connector.receivedFrames.listen(_onFrame);
    connector.addListener(_onConnectorChanged);
    _lastScope = storageScope;
    _lastName = selfName;
    _lastCanSend = canSend;
  }

  void _onFrame(Uint8List frame) {
    if (frame.isEmpty || frame[0] != respCodeChannelDataRecv) return;
    final parsed = parseChannelDataFrame(frame);
    if (parsed == null || parsed.dataType != meshcoreOpenDataType) return;
    if (GamePacketHeader.appOf(parsed.payload) != GameApp.chess) return;
    if (!connector.channelMapConfirmed) {
      // Slot numbers are not trustworthy until the channel list is loaded.
      if (_awaitingMap.length >= _maxBuffered) _awaitingMap.removeAt(0);
      _awaitingMap.add(parsed);
      return;
    }
    _emit(parsed);
  }

  void _emit(ParsedChannelData parsed) {
    final channelId = connector.channelIdForSlot(parsed.channelIndex);
    if (channelId == null) return;
    _incoming.add(ChessIncoming(channelId, parsed.payload));
  }

  void _onConnectorChanged() {
    if (connector.channelMapConfirmed && _awaitingMap.isNotEmpty) {
      final pending = List.of(_awaitingMap);
      _awaitingMap.clear();
      pending.forEach(_emit);
    }
    final scope = storageScope;
    final name = selfName;
    final can = canSend;
    if (scope != _lastScope || name != _lastName || can != _lastCanSend) {
      _lastScope = scope;
      _lastName = name;
      _lastCanSend = can;
      notifyListeners();
    }
  }

  @override
  Stream<ChessIncoming> get incoming => _incoming.stream;

  @override
  Future<bool> send(String channelId, Uint8List payload) async {
    final slot = connector.channels
        .where((c) => c.storageId == channelId)
        .map((c) => c.index)
        .firstOrNull;
    if (slot == null) return false;
    try {
      return await connector.sendChannelData(
        channelIndex: slot,
        dataType: meshcoreOpenDataType,
        payload: payload,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  String get selfName => connector.selfName ?? '';

  @override
  String get storageScope {
    final key = connector.storageKeyHex;
    return key.length >= 10 ? key.substring(0, 10) : '';
  }

  @override
  bool get canSend => connector.supportsChannelData;

  @override
  void notify(String channelId, String text) {
    final s = settings?.settings;
    if (s == null || !s.notificationsEnabled || !s.notifyOnNewChannelMessage) {
      return;
    }
    final channel = connector.channels
        .where((c) => c.storageId == channelId)
        .firstOrNull;
    if (channel == null) return;
    final mode = settings!.getChannelNotificationMode(channel.muteKey);
    if (mode == ChannelNotificationMode.muted) return;
    unawaited(
      NotificationService().showChannelMessageNotification(
        channelName: channel.muteKey,
        senderName: l10n.chess_notificationSender,
        message: text,
        urlImagesEnabled: false,
        channelIndex: channel.index,
      ),
    );
  }

  @override
  AppLocalizations get l10n {
    try {
      final tag = PrefsManager.instance.getString(notificationLanguagePrefsKey);
      if (tag != null && tag.isNotEmpty) {
        return lookupAppLocalizations(localeFromTag(tag));
      }
    } catch (_) {}
    return lookupAppLocalizations(const Locale('en'));
  }

  @override
  void dispose() {
    _frames?.cancel();
    connector.removeListener(_onConnectorChanged);
    _incoming.close();
    super.dispose();
  }
}
