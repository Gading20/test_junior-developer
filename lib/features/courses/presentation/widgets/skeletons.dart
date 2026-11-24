import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/tokens/app_colors.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/widgets/skeleton.dart';

/// Loading skeletons that copy the final layout's shape.
/// They live next to the widgets they imitate, and use design tokens
/// exactly like the real cards.

class CourseCardSkeleton extends StatelessWidget {
  const CourseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 120, height: 68),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 200, height: 14),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 120, height: 12),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 160, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CourseGridCardSkeleton extends StatelessWidget {
  const CourseGridCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonBox(height: 160),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(width: 220, height: 14),
          SizedBox(height: AppSpacing.xs),
          SkeletonBox(width: 140, height: 12),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(width: 180, height: 12),
        ],
      ),
    );
  }
}

class CourseDetailSkeleton extends StatelessWidget {
  const CourseDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: SkeletonBox(height: double.infinity),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonBox(width: 260, height: 20),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonBox(width: 180, height: 14),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonBox(height: 14),
          const SizedBox(height: AppSpacing.xs),
          const SkeletonBox(height: 14),
          const SizedBox(height: AppSpacing.xs),
          const SkeletonBox(width: 200, height: 14),
          const SizedBox(height: AppSpacing.xl),
          ...List.generate(
            5,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: SkeletonBox(height: 56),
            ),
          ),
        ],
      ),
    );
  }
}
