import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../error/failure.dart';
import '../theme/tokens/app_colors.dart';
import '../theme/tokens/app_spacing.dart';
import '../theme/tokens/app_typography.dart';

/// Message shown when there is nothing (or nothing usable) to display:
/// empty data, offline, timeout, or server error.
///
/// One widget for every non-data state keeps wording, icon style, and
/// the retry action identical across screens.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Builds the correct icon/message from a [Failure]; adds a retry
  /// button only when the failure makes retrying useful.
  factory StateView.failure(Failure failure, {VoidCallback? onRetry}) {
    final canRetry = failure.retryable && onRetry != null;
    return StateView(
      icon: iconForFailure(failure.type),
      message: failure.message,
      actionLabel: canRetry ? 'Coba lagi' : null,
      onAction: canRetry ? onRetry : null,
    );
  }

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            // OutlinedButton theme guarantees a 48dp touch target.
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Each failure type gets its own icon, matching its own message.
IconData iconForFailure(FailureType type) => switch (type) {
  FailureType.offline => LucideIcons.wifiOff,
  FailureType.timeout => LucideIcons.timerReset,
  FailureType.server => LucideIcons.serverCrash,
  FailureType.notFound => LucideIcons.searchX,
  FailureType.parsing => LucideIcons.fileWarning,
  FailureType.unknown => LucideIcons.alertTriangle,
};
