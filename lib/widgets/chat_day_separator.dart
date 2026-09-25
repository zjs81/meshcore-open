import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../theme/mesh_theme.dart';

bool isSameChatDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

final Map<(String, bool), DateFormat> _timeFormats = {};

String formatChatTime(BuildContext context, DateTime time) {
  final locale = Localizations.localeOf(context).toString();
  final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
  final format = _timeFormats.putIfAbsent((
    locale,
    use24h,
  ), () => use24h ? DateFormat.Hm(locale) : DateFormat.jm(locale));
  return format.format(time.toLocal());
}

String formatChatDayLabel(BuildContext context, DateTime time) {
  final now = DateTime.now();
  if (isSameChatDay(time, now)) return context.l10n.chat_today;
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  if (isSameChatDay(time, yesterday)) return context.l10n.chat_yesterday;
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).format(time.toLocal());
}

class ChatDaySeparator extends StatelessWidget {
  final DateTime day;

  const ChatDaySeparator({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final line = Expanded(
      child: Container(height: 1, color: color.withValues(alpha: 0.2)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          line,
          const SizedBox(width: 10),
          Text(
            formatChatDayLabel(context, day),
            style: MeshTheme.mono(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          line,
        ],
      ),
    );
  }
}
