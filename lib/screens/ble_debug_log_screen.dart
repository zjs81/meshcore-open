import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../l10n/l10n.dart';
import '../services/ble_debug_log_service.dart';
import '../connector/meshcore_protocol.dart';
import '../widgets/adaptive_app_bar_title.dart';

enum _BleLogView { frames, rawLogRx }

class BleDebugLogScreen extends StatefulWidget {
  const BleDebugLogScreen({super.key});

  @override
  State<BleDebugLogScreen> createState() => _BleDebugLogScreenState();
}

class _BleDebugLogScreenState extends State<BleDebugLogScreen> {
  _BleLogView _view = _BleLogView.frames;

  @override
  Widget build(BuildContext context) {
    return Consumer<BleDebugLogService>(
      builder: (context, logService, _) {
        final entries = logService.entries.reversed.toList();
        final rawEntries = logService.rawLogRxEntries.reversed.toList();
        final showingFrames = _view == _BleLogView.frames;
        final hasEntries = showingFrames
            ? entries.isNotEmpty
            : rawEntries.isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            title: AdaptiveAppBarTitle(context.l10n.debugLog_bleTitle),
            actions: [
              IconButton(
                tooltip: context.l10n.debugLog_copyLog,
                icon: const Icon(Icons.copy),
                onPressed: hasEntries
                    ? () async {
                        final text = showingFrames
                            ? entries
                                  .map(
                                    (entry) =>
                                        '${entry.description}\n${entry.hexPreview}\n',
                                  )
                                  .join('\n')
                            : rawEntries
                                  .map(
                                    (entry) =>
                                        'RX RAW_LOG_RX_DATA\n${entry.hexPreview}\n',
                                  )
                                  .join('\n');
                        await Clipboard.setData(ClipboardData(text: text));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.debugLog_bleCopied),
                          ),
                        );
                      }
                    : null,
              ),
              IconButton(
                tooltip: context.l10n.debugLog_clearLog,
                icon: const Icon(Icons.delete_outline),
                onPressed: hasEntries
                    ? () {
                        logService.clear();
                      }
                    : null,
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SegmentedButton<_BleLogView>(
                    segments: [
                      ButtonSegment(
                        value: _BleLogView.frames,
                        label: Text(context.l10n.debugLog_frames),
                      ),
                      ButtonSegment(
                        value: _BleLogView.rawLogRx,
                        label: Text(context.l10n.debugLog_rawLogRx),
                      ),
                    ],
                    selected: {_view},
                    onSelectionChanged: (selection) {
                      setState(() => _view = selection.first);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: hasEntries
                      ? ListView.separated(
                          itemCount: showingFrames
                              ? entries.length
                              : rawEntries.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (showingFrames) {
                              final entry = entries[index];
                              final time =
                                  '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';
                              return ListTile(
                                dense: true,
                                title: Text(entry.description),
                                subtitle: Text('${entry.hexPreview}\n$time'),
                                isThreeLine: true,
                                leading: Icon(
                                  entry.outgoing
                                      ? Icons.upload
                                      : Icons.download,
                                  size: 18,
                                ),
                                onLongPress: () async {
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text: entry.payload
                                          .map(
                                            (b) => b
                                                .toRadixString(16)
                                                .padLeft(2, '0'),
                                          )
                                          .join(''),
                                    ),
                                  );
                                },
                              );
                            }

                            final entry = rawEntries[index];
                            final info = _decodeRawPacket(entry.payload);
                            final time =
                                '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';
                            return ListTile(
                              dense: true,
                              title: Text(info.title),
                              subtitle: Text('${info.summary}\n$time'),
                              isThreeLine: true,
                              leading: const Icon(Icons.download, size: 18),
                              onTap: () => _showRawDialog(context, info),
                            );
                          },
                        )
                      : Center(
                          child: Text(context.l10n.debugLog_noBleActivity),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRawDialog(BuildContext context, _RawPacketInfo info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(info.title),
        content: SingleChildScrollView(child: SelectableText(info.rawHex)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }

  _RawPacketInfo _decodeRawPacket(Uint8List raw) {
    if (raw.length < 2) {
      return _RawPacketInfo(
        title: 'RX RAW_LOG_RX_DATA • invalid',
        summary: 'Packet too short',
        rawHex: _bytesToHex(raw),
      );
    }

    var index = 0;
    final header = raw[index++];
    final routeType = header & 0x03;
    final payloadType = (header >> 2) & 0x0F;
    final payloadVer = (header >> 6) & 0x03;
    final hasTransport = routeType == 0 || routeType == 3;
    if (hasTransport) {
      if (raw.length < index + 4) {
        return _RawPacketInfo(
          title: 'RX RAW_LOG_RX_DATA • ${_payloadTypeLabel(payloadType)}',
          summary: 'Missing transport codes',
          rawHex: _bytesToHex(raw),
        );
      }
      index += 4;
    }
    if (raw.length <= index) {
      return _RawPacketInfo(
        title: 'RX RAW_LOG_RX_DATA • ${_payloadTypeLabel(payloadType)}',
        summary: 'Missing path length',
        rawHex: _bytesToHex(raw),
      );
    }
    final pathLen = raw[index++];
    if (raw.length < index + pathLen) {
      return _RawPacketInfo(
        title: 'RX RAW_LOG_RX_DATA • ${_payloadTypeLabel(payloadType)}',
        summary: 'Truncated path',
        rawHex: _bytesToHex(raw),
      );
    }
    final pathBytes = raw.sublist(index, index + pathLen);
    index += pathLen;
    if (raw.length <= index) {
      return _RawPacketInfo(
        title: 'RX RAW_LOG_RX_DATA • ${_payloadTypeLabel(payloadType)}',
        summary: 'Missing payload',
        rawHex: _bytesToHex(raw),
      );
    }
    final payload = raw.sublist(index);

    final title =
        'RX ${_payloadTypeLabel(payloadType)} • ${_routeLabel(routeType)} • v$payloadVer';
    final summary = _decodePayloadSummary(payloadType, payload);
    final pathSummary = pathLen > 0
        ? 'Path=${_bytesToHex(pathBytes)}'
        : 'Path=none';
    final detail = '$summary • $pathSummary • len=${raw.length}';
    return _RawPacketInfo(
      title: title,
      summary: detail,
      rawHex: _bytesToHex(raw),
    );
  }

  String _decodePayloadSummary(int payloadType, Uint8List payload) {
    switch (payloadType) {
      case 0x00: // REQ
        return 'REQ payload=${payload.length} bytes';
      case 0x01: // RESP
        return 'RESP payload=${payload.length} bytes';
      case 0x02: // TXT
        return 'TXT payload=${payload.length} bytes';
      case 0x03: // ACK
        if (payload.length < 4) return 'ACK (short)';
        return 'ACK crc=${_bytesToHex(payload.sublist(0, 4))}';
      case 0x04: // ADVERT
        return _decodeAdvertSummary(payload);
      case 0x05: // GROUP_TXT
        if (payload.length < 3) return 'GRP_TXT (short)';
        final channelHash = payload[0].toRadixString(16).padLeft(2, '0');
        final mac = _bytesToHex(payload.sublist(1, 3));
        final cipherLen = payload.length - 3;
        return 'GRP_TXT hash=$channelHash mac=$mac cipher=$cipherLen';
      case 0x06: // GROUP_DATA
        return 'GRP_DATA payload=${payload.length} bytes';
      case 0x07: // ANON_REQ
        return 'ANON_REQ payload=${payload.length} bytes';
      case 0x08: // PATH
        return 'PATH payload=${payload.length} bytes';
      case 0x09: // TRACE
        return 'TRACE payload=${payload.length} bytes';
      case 0x0A: // MULTIPART
        return 'MULTIPART payload=${payload.length} bytes';
      case 0x0B: // CONTROL
        return _decodeControlSummary(payload);
      case 0x0F: // RAW
        return 'RAW payload=${payload.length} bytes';
      default:
        return 'TYPE_$payloadType payload=${payload.length} bytes';
    }
  }

  String _decodeAdvertSummary(Uint8List payload) {
    if (payload.length < 101) {
      return 'ADVERT (short)';
    }
    final reader = BufferReader(payload);
    try {
      final pubKey = _bytesToHex(reader.readBytes(pubKeySize), spaced: false);

      final timestamp = reader.readUInt32LE();
      reader.skipBytes(signatureSize);
      final flags = reader.readByte();
      final role = _deviceRoleLabel(flags & 0x0F);
      final hasLocation = (flags & 0x10) != 0;
      final hasFeature1 = (flags & 0x20) != 0;
      final hasFeature2 = (flags & 0x40) != 0;
      final hasName = (flags & 0x80) != 0;
      String? name;
      double? lat;
      double? lon;
      if (hasLocation) {
        lat = reader.readInt32LE() / 1000000.0;
        lon = reader.readInt32LE() / 1000000.0;
      }
      if (hasFeature1) reader.skipBytes(2);
      if (hasFeature2) reader.skipBytes(2);
      if (hasName) {
        name = reader.readCStringGreedy(maxNameSize);
      }
      final namePart = (name != null && name.isNotEmpty) ? ' name="$name"' : '';
      final locPart = (lat != null && lon != null)
          ? ' loc=${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}'
          : '';
      return 'ADVERT role=$role ts=$timestamp$namePart$locPart key=${pubKey.substring(0, 12)}…';
    } catch (e) {
      return 'ADVERT (invalid)';
    }
  }

  String _decodeControlSummary(Uint8List payload) {
    final reader = BufferReader(payload);
    try {
      final flags = reader.readByte();
      final subType = flags & 0xF0;
      if (subType == 0x80) {
        if (payload.length < 6) return 'CONTROL DISCOVER_REQ (short)';
        final typeFilter = reader.readByte();
        final tag = reader.readInt32LE();
        final since = payload.length >= 10 ? reader.readInt32LE() : 0;
        return 'CONTROL DISCOVER_REQ filter=0x${typeFilter.toRadixString(16).padLeft(2, '0')} tag=$tag since=$since';
      }
      if (subType == 0x90) {
        if (payload.length < 14) return 'CONTROL DISCOVER_RESP (short)';
        final nodeType = flags & 0x0F;
        final snrRaw = payload[1];
        final snrSigned = snrRaw > 127 ? snrRaw - 256 : snrRaw;
        final snr = snrSigned / 4.0;
        final tag = reader.readInt32LE();
        final keyLen = payload.length - 6;
        return 'CONTROL DISCOVER_RESP node=${_deviceRoleLabel(nodeType)} snr=${snr.toStringAsFixed(2)} tag=$tag key=$keyLen';
      }
      return 'CONTROL subtype=0x${subType.toRadixString(16).padLeft(2, '0')}';
    } catch (e) {
      return 'CONTROL (invalid)';
    }
  }

  String _payloadTypeLabel(int payloadType) {
    switch (payloadType) {
      case 0x00:
        return 'REQ';
      case 0x01:
        return 'RESP';
      case 0x02:
        return 'TXT';
      case 0x03:
        return 'ACK';
      case 0x04:
        return 'ADVERT';
      case 0x05:
        return 'GRP_TXT';
      case 0x06:
        return 'GRP_DATA';
      case 0x07:
        return 'ANON_REQ';
      case 0x08:
        return 'PATH';
      case 0x09:
        return 'TRACE';
      case 0x0A:
        return 'MULTIPART';
      case 0x0B:
        return 'CONTROL';
      case 0x0F:
        return 'RAW';
      default:
        return 'TYPE_$payloadType';
    }
  }

  String _routeLabel(int routeType) {
    switch (routeType) {
      case 0:
        return 'TRANS_FLOOD';
      case 1:
        return 'FLOOD';
      case 2:
        return 'DIRECT';
      case 3:
        return 'TRANS_DIRECT';
      default:
        return 'ROUTE_$routeType';
    }
  }

  String _deviceRoleLabel(int role) {
    switch (role) {
      case 0x01:
        return 'Chat';
      case 0x02:
        return 'Repeater';
      case 0x03:
        return 'Room';
      case 0x04:
        return 'Sensor';
      default:
        return 'Unknown';
    }
  }

  String _bytesToHex(Uint8List bytes, {bool spaced = true}) {
    if (bytes.isEmpty) return '';
    if (!spaced) {
      return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    }
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }
}

class _RawPacketInfo {
  final String title;
  final String summary;
  final String rawHex;

  _RawPacketInfo({
    required this.title,
    required this.summary,
    required this.rawHex,
  });
}
