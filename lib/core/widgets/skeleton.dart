import 'package:material_ui/material_ui.dart';

import '../theme/tokens/app_colors.dart';
import '../theme/tokens/app_radius.dart';

/// Gray block shaped like the real content it replaces, so the layout
/// does not jump when data arrives (no spinner in the middle).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.md,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
