import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../utils/app_logger.dart';
import 'path_management_dialog.dart';

class RoomLoginDialog extends StatefulWidget {
  final Contact room;
  final Function(String password) onLogin;

  const RoomLoginDialog({
    super.key,
    required this.room,
    required this.onLogin,
  });

  @override
  State<RoomLoginDialog> createState() => _RoomLoginDialogState();
}

class _RoomLoginDialogState extends State<RoomLoginDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final StorageService _storage = StorageService();
  bool _savePassword = false;
  bool _isLoading = true;
  bool _obscurePassword = true;
  late MeshCoreConnector _connector;
  int _currentAttempt = 0;
  static const int _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    _connector = Provider.of<MeshCoreConnector>(context, listen: false);
    _loadSavedPassword();
  }

  Future<void> _loadSavedPassword() async {
    final savedPassword =
        await _storage.getRepeaterPassword(widget.room.publicKeyHex);
    if (savedPassword != null) {
      setState(() {
        _passwordController.text = savedPassword;
        _savePassword = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  bool _isLoggingIn = false;

  Contact _resolveRepeater(MeshCoreConnector connector) {
    return connector.contacts.firstWhere(
      (c) => c.publicKeyHex == widget.room.publicKeyHex,
      orElse: () => widget.room,
    );
  }

  Future<void> _handleLogin() async {
    if (_isLoggingIn) return;

    setState(() {
      _isLoggingIn = true;
      _currentAttempt = 0;
    });

    try {
      final password = _passwordController.text;
      final room = _resolveRepeater(_connector);
      appLogger.info(
        'Login started for ${room.name} (${room.publicKeyHex})',
        tag: 'RoomLogin',
      );
      final selection = await _connector.preparePathForContactSend(room);
      final loginFrame = buildSendLoginFrame(room.publicKey, password);
      final pathLengthValue = selection.useFlood ? -1 : selection.hopCount;
      final timeoutMs = _connector.calculateTimeout(
        pathLength: pathLengthValue,
        messageBytes: loginFrame.length,
      );
      final timeoutSeconds = (timeoutMs / 1000).ceil();
      final timeout = Duration(milliseconds: timeoutMs);
      final selectionLabel =
          selection.useFlood ? 'flood' : '${selection.hopCount} hops';
      appLogger.info(
        'Login routing: $selectionLabel',
        tag: 'RoomLogin',
      );
      bool? loginResult;
      for (int attempt = 0; attempt < _maxAttempts; attempt++) {
        if (!mounted) return;
        setState(() {
          _currentAttempt = attempt + 1;
        });

        appLogger.info(
          'Sending login attempt ${attempt + 1}/$_maxAttempts',
          tag: 'RoomLogin',
        );
        await _connector.sendFrame(
          loginFrame,
        );

        loginResult = await _awaitLoginResponse(timeout);
        if (loginResult == true) {
          appLogger.info(
            'Login succeeded for ${room.name}',
            tag: 'RoomLogin',
          );
          break;
        }
        if (loginResult == false) {
          appLogger.warn(
            'Login failed for ${room.name}',
            tag: 'RoomLogin',
          );
          throw Exception('Wrong password or node is unreachable');
        }
        appLogger.warn(
          'Login attempt ${attempt + 1} timed out after ${timeoutSeconds}s',
          tag: 'RoomLogin',
        );
      }

      if (loginResult == null) {
        appLogger.warn(
          'Login timed out for ${room.name}',
          tag: 'RoomLogin',
        );
      }

      if (loginResult == true) {
        _connector.recordRepeaterPathResult(room, selection, true, null);
      } else {
        _connector.recordRepeaterPathResult(room, selection, false, null);
      }

      if (loginResult != true) {
        throw Exception('Wrong password or node is unreachable');
      }

      // If we got a response, login succeeded
      // Save password if requested
      if (_savePassword) {
        await _storage.saveRepeaterPassword(
            widget.room.publicKeyHex, password);
      } else {
        // Remove saved password if user unchecked the box
        await _storage.removeRepeaterPassword(widget.room.publicKeyHex);
      }

      if (mounted) {
        Navigator.pop(context, password);
        Future.microtask(() => widget.onLogin(password));
      }
    } catch (e) {
      final room = _resolveRepeater(_connector);
      appLogger.warn(
        'Login error for ${room.name}: $e',
        tag: 'RoomLogin',
      );
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _awaitLoginResponse(Duration timeout) async {
    final completer = Completer<bool?>();
    Timer? timer;
    StreamSubscription<Uint8List>? subscription;
    final targetPrefix = widget.room.publicKey.sublist(0, 6);

    subscription = _connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      final code = frame[0];
      if (code != pushCodeLoginSuccess && code != pushCodeLoginFail) return;
      if (frame.length < 8) return;
      final prefix = frame.sublist(2, 8);
      if (!listEquals(prefix, targetPrefix)) return;

      completer.complete(code == pushCodeLoginSuccess);
      subscription?.cancel();
      timer?.cancel();
    });

    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
        subscription?.cancel();
      }
    });

    final result = await completer.future;
    timer.cancel();
    await subscription.cancel();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final connector = context.watch<MeshCoreConnector>();
    final repeater = _resolveRepeater(connector);
    final isFloodMode = repeater.pathOverride == -1;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.group, color: Colors.purple),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Room Login'),
                Text(
                  repeater.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the room password to access settings and status.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  onSubmitted: (_) => _handleLogin(),
                  autofocus: _passwordController.text.isEmpty,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _savePassword,
                  onChanged: (value) {
                    setState(() {
                      _savePassword = value ?? false;
                    });
                  },
                  title: const Text(
                    'Save password',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Password will be stored securely on this device',
                    style: TextStyle(fontSize: 12),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                Row(
                  children: [
                    const Text(
                      'Routing',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: Icon(isFloodMode ? Icons.waves : Icons.route),
                      tooltip: 'Routing mode',
                      onSelected: (mode) async {
                        if (mode == 'flood') {
                          await connector.setPathOverride(repeater, pathLen: -1);
                        } else {
                          await connector.setPathOverride(repeater, pathLen: null);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'auto',
                          child: Row(
                            children: [
                              Icon(Icons.auto_mode, size: 20, color: !isFloodMode ? Theme.of(context).primaryColor : null),
                              const SizedBox(width: 8),
                              Text(
                                'Auto (use saved path)',
                                style: TextStyle(
                                  fontWeight: !isFloodMode ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'flood',
                          child: Row(
                            children: [
                              Icon(Icons.waves, size: 20, color: isFloodMode ? Theme.of(context).primaryColor : null),
                              const SizedBox(width: 8),
                              Text(
                                'Force Flood Mode',
                                style: TextStyle(
                                  fontWeight: isFloodMode ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  repeater.pathLabel,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => PathManagementDialog.show(context, contact: repeater),
                    icon: const Icon(Icons.timeline, size: 18),
                    label: const Text('Manage Paths'),
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_isLoggingIn)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Attempt $_currentAttempt/$_maxAttempts'),
                ],
              ),
            ),
          )
        else
          FilledButton.icon(
            onPressed: _isLoading ? null : _handleLogin,
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Login'),
          ),
      ],
    );
  }
}
