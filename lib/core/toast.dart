import 'dart:async';

import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

OverlayEntry? _entry;
Timer? _timer;

/// Top toast — for feedback while a bottom sheet / keyboard would hide a
/// regular snackbar. A new toast replaces the previous one. Auto-dismisses
/// after [duration]; optional single action (Undo).
void showTopToast(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  _close();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Material(
        color: kInk,
        borderRadius: BorderRadius.circular(kRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _close();
                    onAction();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  _entry = entry;
  Overlay.of(context).insert(entry);
  _timer = Timer(duration, _close);
}

void _close() {
  _timer?.cancel();
  _timer = null;
  final entry = _entry;
  _entry = null;
  if (entry != null && entry.mounted) entry.remove();
}
