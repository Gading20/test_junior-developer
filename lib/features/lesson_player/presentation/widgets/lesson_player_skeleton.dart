import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/widgets/skeleton.dart';

/// Loading skeleton for the player screen: the same 16:9 block, title
/// lines and lesson rows the real screen renders, so nothing jumps
/// when the course detail arrives.
class LessonPlayerSkeleton extends StatelessWidget {
  const LessonPlayerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: SkeletonBox(height: double.infinity),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonBox(width: 200, height: 12),
              SizedBox(height: AppSpacing.xs),
              SkeletonBox(width: double.infinity, height: 24),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(width: 180, height: 12),
              SizedBox(height: AppSpacing.xl),
              SkeletonBox(width: 160, height: 14),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(width: double.infinity, height: 48),
              SizedBox(height: AppSpacing.lg),
              SkeletonBox(width: 180, height: 16),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(width: double.infinity, height: 56),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(width: double.infinity, height: 56),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(width: double.infinity, height: 56),
            ],
          ),
        ),
      ],
    );
  }
}
