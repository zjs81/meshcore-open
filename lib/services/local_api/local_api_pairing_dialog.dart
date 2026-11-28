import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../notification_service.dart';
import 'local_api_pairing.dart';
import 'local_api_service.dart';

/// Shows the consent dialog when an app asks to use the radio.
///
/// Wraps the app so the dialog can appear over any screen. Nothing is granted
/// silently: an unanswered request times out and is denied, and its dialog
/// closes when the request ends without an answer. A request that arrives
/// while the app is in the background also posts a notification, since the
/// dialog cannot be seen until the user comes back.
class LocalApiPairingHost extends StatefulWidget {
  final Widget child;

  const LocalApiPairingHost({super.key, required this.child});

  @override
  State<LocalApiPairingHost> createState() => _LocalApiPairingHostState();
}

class _LocalApiPairingHostState extends State<LocalApiPairingHost>
    with WidgetsBindingObserver {
  final List<StreamSubscription<Object>> _subscriptions = [];
  final List<PairingRequest> _queue = [];
  PairingRequest? _showing;
  BuildContext? _dialogContext;

  PairingBroker? get _broker => LocalApiService.instance?.pairingBroker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final broker = _broker;
    if (broker != null) {
      _subscriptions
        ..add(broker.requests.listen(_enqueue))
        ..add(broker.cancelled.listen(_onCancelled));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back in front: the dialog is visible, the notification has done its job.
    if (state == AppLifecycleState.resumed) _clearNotification();
  }

  bool get _inBackground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state != null && state != AppLifecycleState.resumed;
  }

  void _clearNotification() {
    unawaited(NotificationService().clearLocalApiPairingRequest());
  }

  void _enqueue(PairingRequest request) {
    _queue.add(request);
    if (_inBackground) {
      unawaited(NotificationService().showLocalApiPairingRequest(request.name));
    }
    unawaited(_showNext());
  }

  void _onCancelled(String id) {
    _queue.removeWhere((request) => request.id == id);
    if (_queue.isEmpty && (_showing == null || _showing?.id == id)) {
      _clearNotification();
    }
    final dialogContext = _dialogContext;
    if (_showing?.id == id &&
        dialogContext != null &&
        dialogContext.mounted &&
        (ModalRoute.of(dialogContext)?.isCurrent ?? false)) {
      Navigator.pop(dialogContext);
    }
  }

  Future<void> _showNext() async {
    if (_showing != null || !mounted || _queue.isEmpty) return;
    final request = _queue.removeAt(0);
    _showing = request;
    final allowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        _dialogContext = context;
        final l10n = context.l10n;
        final channelName = request.channelName;
        if (channelName != null) {
          return AlertDialog(
            title: Text(l10n.localApi_joinTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.localApi_joinBody(request.name, channelName)),
                const SizedBox(height: 16),
                Text(
                  l10n.localApi_joinWarning,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.localApi_deny),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.localApi_joinAdd),
              ),
            ],
          );
        }
        return AlertDialog(
          title: Text(l10n.localApi_pairTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.localApi_pairBody(request.name)),
              const SizedBox(height: 16),
              Text(
                l10n.localApi_keyFingerprint,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              SelectableText(
                request.fingerprint,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.localApi_pairWarning,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.localApi_deny),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.localApi_allow),
            ),
          ],
        );
      },
    );
    _dialogContext = null;
    _showing = null;
    if (_queue.isEmpty) _clearNotification();
    final answered = _broker?.resolve(request.id, allowed ?? false) ?? false;
    if (allowed == true &&
        !answered &&
        request.channelName == null &&
        mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(context.l10n.localApi_pairExpired(request.name)),
        ),
      );
    }
    if (_queue.isNotEmpty) unawaited(_showNext());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
