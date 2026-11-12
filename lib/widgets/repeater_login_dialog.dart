import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../l10n/contact_localization.dart';
import '../services/storage_service.dart';
import '../services/repeater_command_service.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../theme/mesh_theme.dart';
import '../widgets/mesh_ui.dart';
import '../utils/app_logger.dart';
import '../helpers/utf8_length_limiter.dart';
import 'path_editor_sheet.dart';
import 'routing_sheet.dart';
import '../utils/radio_guard.dart';

class RepeaterLoginDialog extends StatefulWidget {
  final Contact repeater;
  final Function(String password, bool isAdmin) onLogin;

  const RepeaterLoginDialog({
    super.key,
    required this.repeater,
    required this.onLogin,
  });

  @override
  State<RepeaterLoginDialog> createState() => _RepeaterLoginDialogState();
}

class _RepeaterLoginDialogState extends State<RepeaterLoginDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final StorageService _storage = StorageService();
  final GlobalKey _loginButtonKey = GlobalKey();
  bool _savePassword = false;
  bool _isLoading = true;
  bool _obscurePassword = true;
  String? _loginError;
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
    final savedPassword = await _storage.getRepeaterPassword(
      widget.repeater.publicKeyHex,
    );
    if (!mounted) return;
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

  int _resolveRepeaterIndex = -1;
  Contact _resolveRepeater(MeshCoreConnector connector) {
    if (_resolveRepeaterIndex >= 0 &&
        _resolveRepeaterIndex < connector.contacts.length &&
        connector.contacts[_resolveRepeaterIndex].publicKeyHex ==
            widget.repeater.publicKeyHex) {
      return connector.contacts[_resolveRepeaterIndex];
    }
    _resolveRepeaterIndex = connector.contacts.indexWhere(
      (c) => c.publicKeyHex == widget.repeater.publicKeyHex,
    );
    if (_resolveRepeaterIndex == -1) {
      return widget.repeater;
    }
    return connector.contacts[_resolveRepeaterIndex];
  }

  Future<void> _handleLogin() async {
    if (_isLoggingIn) return;
    if (!ensureRadioConnected(context)) return;

    setState(() {
      _isLoggingIn = true;
      _currentAttempt = 0;
      _loginError = null;
    });

    try {
      final password = _passwordController.text;
      final repeater = _resolveRepeater(_connector);
      appLogger.info(
        'Login started for ${repeater.name} (${repeater.publicKeyHex})',
        tag: 'RepeaterLogin',
      );
      final selection = await _connector.preparePathForContactSend(repeater);
      final loginFrame = buildSendLoginFrame(repeater.publicKey, password);
      final pathLengthValue = selection.useFlood ? -1 : selection.hopCount;
      final responseBytes = loginFrame.length > maxFrameSize
          ? loginFrame.length
          : maxFrameSize;
      final timeoutMs = _connector.calculateTimeout(
        pathLength: pathLengthValue,
        messageBytes: responseBytes,
      );
      final timeoutSeconds = (timeoutMs / 1000).ceil();
      final timeout = Duration(milliseconds: timeoutMs + 2000);
      final selectionLabel = selection.useFlood
          ? 'flood'
          : '${selection.hopCount} hops';
      appLogger.info('Login routing: $selectionLabel', tag: 'RepeaterLogin');
      bool? loginResult;
      bool isAdmin = false;
      for (int attempt = 0; attempt < _maxAttempts; attempt++) {
        if (!mounted) return;
        setState(() {
          _currentAttempt = attempt + 1;
        });

        appLogger.info(
          'Sending login attempt ${attempt + 1}/$_maxAttempts',
          tag: 'RepeaterLogin',
        );
        await _connector.sendFrame(loginFrame);

        (loginResult, isAdmin) = await _awaitLoginResponse(timeout);
        if (loginResult == true) {
          appLogger.info(
            'Login succeeded for ${repeater.name}',
            tag: 'RepeaterLogin',
          );
          break;
        }
        if (loginResult == false) {
          appLogger.warn(
            'Login failed for ${repeater.name}',
            tag: 'RepeaterLogin',
          );
          break;
        }
        appLogger.warn(
          'Login attempt ${attempt + 1} timed out after ${timeoutSeconds}s',
          tag: 'RepeaterLogin',
        );
      }

      if (loginResult == null) {
        appLogger.warn(
          'Login timed out for ${repeater.name}',
          tag: 'RepeaterLogin',
        );
      }

      if (loginResult == true) {
        _connector.recordRepeaterPathResult(repeater, selection, true, null);
      } else {
        _connector.recordRepeaterPathResult(repeater, selection, false, null);
      }

      if (loginResult != true) {
        if (mounted) {
          setState(() {
            _isLoggingIn = false;
            _loginError = context.l10n.login_failedMessage;
          });
        }
        return;
      }

      // If we got a response, login succeeded
      // Save password if requested
      if (_savePassword) {
        await _storage.saveRepeaterPassword(
          widget.repeater.publicKeyHex,
          password,
        );
      } else {
        // Remove saved password if user unchecked the box
        await _storage.removeRepeaterPassword(widget.repeater.publicKeyHex);
      }

      final autoClockSync = await _storage
          .getRepeaterAutoClockSyncAfterLoginEnabled(
            widget.repeater.publicKeyHex,
          );
      if (autoClockSync) {
        try {
          final timestampSeconds =
              DateTime.now().millisecondsSinceEpoch ~/ 1000;
          await _connector.sendFrame(
            buildSendCliCommandFrame(
              repeater.publicKey,
              normalizeRepeaterClockSyncCommand(
                'clock sync',
                nowSeconds: timestampSeconds,
              ),
              timestampSeconds: timestampSeconds,
            ),
          );
        } catch (e) {
          appLogger.warn(
            'Auto clock sync failed for ${repeater.name}: $e',
            tag: 'RepeaterLogin',
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, password);
        Future.microtask(() => widget.onLogin(password, isAdmin));
      }
    } catch (e) {
      final repeater = _resolveRepeater(_connector);
      appLogger.warn(
        'Login error for ${repeater.name}: $e',
        tag: 'RepeaterLogin',
      );
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
          _loginError = context.l10n.login_failedMessage;
        });
      }
    }
  }

  // _awaitLoginResponse returns a record of bool, for success and if the client is an admin
  Future<(bool?, bool)> _awaitLoginResponse(Duration timeout) {
    return awaitRepeaterLoginResponse(
      _connector,
      widget.repeater.publicKey.sublist(0, 6),
      timeout,
    );
  }

  bool _hasManualPath(Contact repeater) {
    final override = repeater.pathOverride;
    return override != null && override > 0;
  }

  /// Opens the path editor straight from the routing menu so a login path can
  /// be set without leaving the dialog flow.
  Future<void> _setPathDirectly(
    MeshCoreConnector connector,
    Contact repeater,
  ) async {
    final override = repeater.pathOverride;
    final initial = override != null && override > 0
        ? (repeater.pathOverrideBytes ?? Uint8List(0))
        : (repeater.pathLength > 0 &&
                  repeater.pathHashWidth == connector.pathHashByteWidth
              ? repeater.path
              : Uint8List(0));
    final available = connector.allContacts
        .where((c) => c.publicKeyHex != repeater.publicKeyHex)
        .toList();
    final result = await PathEditorSheet.show(
      context,
      availableContacts: available,
      initialPath: initial,
      pathHashByteWidth: connector.pathHashByteWidth,
    );
    if (result == null || !mounted) return;
    final hopCount = result.length ~/ connector.pathHashByteWidth;
    await connector.setPathOverride(
      repeater,
      pathLen: hopCount,
      pathBytes: result,
    );
    if (mounted) setState(() {});
  }

  void _showLoginOptions() {
    if (_isLoggingIn || _isLoading) return;
    unawaited(_presentLoginOptions());
  }

  Future<void> _presentLoginOptions() async {
    final l10n = context.l10n;
    final buttonContext = _loginButtonKey.currentContext;
    final button = buttonContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          button.size.bottomLeft(Offset.zero),
          ancestor: overlay,
        ),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    final value = await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'direct',
          child: Row(
            children: [
              Icon(Icons.my_location, size: 20, color: MeshPalette.signal),
              const SizedBox(width: 8),
              Text(l10n.login_directLogin),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'auto',
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 20),
              const SizedBox(width: 8),
              Text(l10n.login_autoLogin),
            ],
          ),
        ),
      ],
    );
    if (!mounted) return;
    if (value == 'direct') {
      await _loginDirectly();
    } else if (value == 'auto') {
      await _loginAutomatically();
    }
  }

  Future<void> _loginDirectly() async {
    if (_isLoggingIn) return;
    final repeater = _resolveRepeater(_connector);
    await _connector.setPathOverride(
      repeater,
      pathLen: 0,
      pathBytes: Uint8List(0),
    );
    if (!mounted) return;
    setState(() {});
    await _handleLogin();
  }

  Future<void> _loginAutomatically() async {
    if (_isLoggingIn) return;
    final savedPassword = await _storage.getRepeaterPassword(
      widget.repeater.publicKeyHex,
    );
    if (!mounted) return;
    if (savedPassword != null) {
      _passwordController.text = savedPassword;
    }
    await _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final connector = context.watch<MeshCoreConnector>();
    final repeater = _resolveRepeater(connector);
    final isFloodMode = repeater.pathOverride == -1;
    final isDirectMode = repeater.pathOverride == 0;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      title: Row(
        children: [
          AvatarCircle(
            name: repeater.name,
            size: 40,
            color: MeshPalette.warn,
            icon: Icons.cell_tower,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.login_repeaterLogin,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  repeater.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.login_repeaterDescription,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  if (_loginError != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error, size: 18, color: scheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loginError!,
                            style: TextStyle(color: scheme.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    // Firmware stores at most 15 bytes (CommonCLI.h password[16]).
                    inputFormatters: const [
                      Utf8LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.login_password,
                      hintText: l10n.login_enterPassword,
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        tooltip: _obscurePassword
                            ? l10n.login_showPassword
                            : l10n.login_hidePassword,
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    onChanged: (_) {
                      if (_loginError != null && mounted) {
                        setState(() {
                          _loginError = null;
                        });
                      }
                    },
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
                    title: Text(
                      l10n.login_savePassword,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      l10n.login_savePasswordSubtitle,
                      style: const TextStyle(fontSize: 12),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  ExpansionTile(
                    title: Text(l10n.login_advanced),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.login_routing,
                            style: MeshTheme.accentLabel(
                              color: scheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            icon: Icon(
                              isFloodMode
                                  ? Icons.waves
                                  : isDirectMode
                                  ? Icons.my_location
                                  : Icons.route,
                            ),
                            tooltip: l10n.login_routingMode,
                            onSelected: (mode) async {
                              if (mode == 'flood') {
                                await connector.setPathOverride(
                                  repeater,
                                  pathLen: -1,
                                );
                              } else if (mode == 'auto') {
                                await connector.setPathOverride(
                                  repeater,
                                  pathLen: null,
                                );
                              } else if (mode == 'direct') {
                                await connector.setPathOverride(
                                  repeater,
                                  pathLen: 0,
                                  pathBytes: Uint8List(0),
                                );
                              } else if (mode == 'path') {
                                await _setPathDirectly(connector, repeater);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'auto',
                                child: MeshMenuItemRow(
                                  icon: Icons.auto_mode,
                                  label: l10n.login_autoUseSavedPath,
                                  iconColor: !isFloodMode
                                      ? scheme.primary
                                      : null,
                                  selected: !isFloodMode,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'path',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_road,
                                      size: 20,
                                      color: _hasManualPath(repeater)
                                          ? scheme.primary
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.login_setPath,
                                      style: TextStyle(
                                        fontWeight: _hasManualPath(repeater)
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'direct',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.my_location,
                                      size: 20,
                                      color: isDirectMode
                                          ? scheme.primary
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.login_directMode,
                                      style: TextStyle(
                                        fontWeight: isDirectMode
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'flood',
                                child: MeshMenuItemRow(
                                  icon: Icons.waves,
                                  label: l10n.login_forceFloodMode,
                                  iconColor: isFloodMode
                                      ? scheme.primary
                                      : null,
                                  selected: isFloodMode,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        repeater.pathLabel(
                          context.l10n,
                          pathHashByteWidth: connector.pathHashByteWidth,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => ContactRoutingSheet.show(
                            context,
                            contact: repeater,
                          ),
                          icon: const Icon(Icons.timeline, size: 18),
                          label: Text(l10n.login_managePaths),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        if (_isLoggingIn)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.login_attempt(_currentAttempt, _maxAttempts)),
                ],
              ),
            ),
          )
        else
          FilledButton.icon(
            key: _loginButtonKey,
            onPressed: _isLoading ? null : _handleLogin,
            onLongPress: _isLoading ? null : _showLoginOptions,
            icon: const Icon(Icons.login, size: 18),
            label: Text(l10n.login_login),
          ),
      ],
    );
  }
}

/// Waits for the login success/failure push for [targetPrefix]. The success
/// flag is null when no response arrived before [timeout]; the second flag
/// reports whether the repeater answered with admin permissions.
Future<(bool?, bool)> awaitRepeaterLoginResponse(
  MeshCoreConnector connector,
  Uint8List targetPrefix,
  Duration timeout,
) async {
  final completer = Completer<bool?>();
  Timer? timer;
  StreamSubscription<Uint8List>? subscription;
  bool isAdmin = false;
  subscription = connector.receivedFrames.listen((frame) {
    if (frame.isEmpty) return;
    final code = frame[0];
    if (code != pushCodeLoginSuccess && code != pushCodeLoginFail) return;
    if (frame.length < 8) return;
    // NOTE: a bug in the repeater firmware only ever sends 1 or 0 back, not the
    // expected client permissions
    isAdmin = (frame[1] == 1);
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
  return (result, isAdmin);
}
