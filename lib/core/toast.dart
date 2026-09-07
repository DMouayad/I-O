import 'dart:async';

import 'package:flutter/material.dart';

import 'theme/palette.dart';

/// Stacked top toasts — visible above bottom sheet / keyboard where a
/// regular snackbar would hide. Toasts queue instead of replacing each
/// other so rapid entry never destroys a pending Undo.
class _ToastData {
  _ToastData({
    required this.message,
    this.actionLabel,
    this.onAction,
    this.duration = const Duration(seconds: 4),
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
}

OverlayEntry? _entry;
final List<_ToastData> _queue = [];
final List<Timer> _timers = [];

/// Max simultaneous toasts; oldest is dismissed first.
const int kMaxToasts = 3;

void showTopToast(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  _queue.add(
    _ToastData(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    ),
  );
  while (_queue.length > kMaxToasts) {
    _queue.removeAt(0);
  }
  _refresh(context);
}

void _refresh(BuildContext context) {
  _closeEntry();
  if (_queue.isEmpty) return;
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  final topPad = MediaQuery.of(context).padding.top + 12;
  final items = List<_ToastData>.of(_queue);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: topPad,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ToastCard(
              data: items[i],
              onDismissed: () {
                _queue.remove(items[i]);
                // Rebuild with remaining items; needs a live context.
                try {
                  _refresh(context);
                } catch (_) {
                  _closeEntry();
                }
              },
            ),
          ],
        ],
      ),
    ),
  );
  _entry = entry;
  overlay.insert(entry);
  // Single timer dismisses the oldest toast, then re-renders the rest.
  for (final t in _timers) {
    t.cancel();
  }
  _timers.clear();
  if (_queue.isNotEmpty) {
    _timers.add(
      Timer(_queue.first.duration, () {
        if (_queue.isNotEmpty) _queue.removeAt(0);
        try {
          _refresh(context);
        } catch (_) {
          _closeEntry();
        }
      }),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.data, required this.onDismissed});

  final _ToastData data;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Semantics(
      liveRegion: true,
      label: data.actionLabel == null
          ? data.message
          : '${data.message}. ${data.actionLabel}',
      child: Material(
        color: pal.primary,
        borderRadius: BorderRadius.circular(kRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  data.message,
                  style: TextStyle(
                    color: pal.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (data.actionLabel != null && data.onAction != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    final action = data.onAction!;
                    onDismissed();
                    action();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: pal.onPrimary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(48, 40),
                  ),
                  child: Text(
                    data.actionLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void _closeEntry() {
  final entry = _entry;
  _entry = null;
  if (entry != null && entry.mounted) entry.remove();
}
