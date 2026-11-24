import 'package:material_ui/material_ui.dart';

import '../theme/tokens/app_spacing.dart';
import '../theme/tokens/app_typography.dart';

/// Left-aligned section title with an optional right-side detail,
/// used by every screen that groups content (course detail, player).
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(title, style: AppTypography.titleM)),
          if (trailing != null) Text(trailing!, style: AppTypography.caption),
        ],
      ),
    );
  }
}
