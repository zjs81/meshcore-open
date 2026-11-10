import 'package:flutter/material.dart';

import '../screens/channels_screen.dart';

/// Shows the main screens as the only route once a radio has connected.
void navigateToMainAfterConnect(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const ChannelsScreen()),
    (_) => false,
  );
}
