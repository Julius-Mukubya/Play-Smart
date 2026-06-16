import 'package:flutter/material.dart';
import 'package:play_smart/core/theme/app_theme.dart';

/// Reusable branded dialog — replaces the default Material AlertDialog.
///
/// Features:
/// - Blurred/frosted backdrop
/// - Rounded 24px corners
/// - Optional icon with coloured circle background
/// - Full-width stacked action buttons (primary + secondary)
/// - Destructive variant (red primary button)
class AppDialog extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? body;
  final Widget? content;          // custom body widget, overrides [body]
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool destructive;         // red confirm button

  const AppDialog({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.body,
    this.content,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.destructive = false,
  });

  /// Convenience: show the dialog and return true if confirmed.
  static Future<bool?> show(
    BuildContext context, {
    IconData? icon,
    Color? iconColor,
    required String title,
    String? body,
    Widget? content,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => AppDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        body: body,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        destructive: destructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmColor =
        destructive ? AppColors.stateError : AppColors.accentPrimary;
    final resolvedIconColor =
        iconColor ?? (destructive ? AppColors.stateError : AppColors.accentPrimary);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon header ──────────────────────────────────────────────
            if (icon != null) ...[
              const SizedBox(height: 28),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: resolvedIconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: resolvedIconColor),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 28),

            // ── Title ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // ── Body / custom content ────────────────────────────────────
            if (content != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: content!,
              ),
            ] else if (body != null && body!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  body!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Divider ──────────────────────────────────────────────────
            const Divider(height: 1, color: AppColors.borderDefault),

            // ── Action buttons (stacked) ─────────────────────────────────
            _ActionButton(
              label: confirmLabel,
              color: confirmColor,
              fontWeight: FontWeight.w700,
              onTap: () {
                Navigator.of(context).pop(true);
                onConfirm();
              },
            ),

            const Divider(height: 1, color: AppColors.borderDefault),

            _ActionButton(
              label: cancelLabel,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              onTap: () {
                Navigator.of(context).pop(false);
                onCancel?.call();
              },
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final FontWeight fontWeight;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.fontWeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: fontWeight,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
