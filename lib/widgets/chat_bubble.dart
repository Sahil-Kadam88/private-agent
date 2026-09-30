import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../theme/app_colors.dart';

/// Transcript bubble for user / agent / system / error messages.
///
/// Follows the 60-30-10 hierarchy: user messages are high-contrast black
/// (30% secondary), agent messages sit on quiet light surfaces (60%),
/// and the red accent marks step/error indicators (10%).
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat.Hm().format(message.time);

    switch (message.role) {
      case ChatRole.user:
        return _bubble(
          context,
          alignment: Alignment.centerRight,
          color: theme.colorScheme.secondary,
          textColor: theme.colorScheme.onSecondary,
          child: Text(
            message.text,
            style:
                TextStyle(color: theme.colorScheme.onSecondary, height: 1.35),
          ),
          time: time,
        );
      case ChatRole.agent:
        return _bubble(
          context,
          alignment: Alignment.centerLeft,
          color: theme.colorScheme.surfaceContainerHighest,
          textColor: theme.colorScheme.onSurface,
          header: message.step != null
              ? _stepChip(context, 'Step ${message.step}')
              : null,
          child: MarkdownBody(
            data: message.text,
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              code: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                backgroundColor:
                    theme.colorScheme.outline.withValues(alpha: 0.25),
              ),
            ),
          ),
          time: time,
        );
      case ChatRole.system:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      case ChatRole.error:
        return _bubble(
          context,
          alignment: Alignment.centerLeft,
          color: AppColors.error.withValues(alpha: 0.15),
          textColor: theme.colorScheme.onSurface,
          header: _stepChip(context, 'Error', color: AppColors.error),
          child: Text(
            message.text,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.error, height: 1.35),
          ),
          time: time,
        );
    }
  }

  Widget _stepChip(BuildContext context, String label, {Color? color}) {
    // Step indicators use the accent (primary) when no explicit color is set.
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }

  Widget _bubble(
    BuildContext context, {
    required Alignment alignment,
    required Color color,
    required Color textColor,
    required Widget child,
    required String time,
    Widget? header,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ?header,
            child,
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: textColor.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
