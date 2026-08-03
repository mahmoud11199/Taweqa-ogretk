import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

OverlayEntry? _currentToast;
Timer? _toastTimer;

void showToast(BuildContext context, String message, {bool isError = false}) {
  _toastTimer?.cancel();
  _toastTimer = null;
  final old = _currentToast;
  _currentToast = null;
  if (old?.mounted == true) {
    old!.remove();
  }

  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isError ? AppTheme.error : AppTheme.meterCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  _currentToast = entry;

  _toastTimer = Timer(const Duration(seconds: 3), () {
    if (entry.mounted) entry.remove();
    if (_currentToast == entry) _currentToast = null;
  });
}
