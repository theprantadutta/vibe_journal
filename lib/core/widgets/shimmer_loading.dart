// lib/core/widgets/shimmer_loading.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';

/// Shimmer loading widget for skeleton screens
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    Key? key,
    required this.child,
    this.isLoading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
      highlightColor: isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.lightBackground,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

/// Preset shimmer shapes for common use cases
class ShimmerShapes {
  /// Rectangle shimmer placeholder
  static Widget rectangle({
    required double width,
    required double height,
    double borderRadius = AppSpacing.radiusMd,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// Circle shimmer placeholder
  static Widget circle({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  /// Text line shimmer placeholder
  static Widget textLine({
    double width = double.infinity,
    double height = 16,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
    );
  }

  /// Card shimmer placeholder
  static Widget card({
    double? height,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      height: height ?? 120,
      margin: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
            vertical: AppSpacing.elementSpacing,
          ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
    );
  }

  /// List item shimmer placeholder
  static Widget listItem() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingHorizontal,
        vertical: AppSpacing.elementSpacing,
      ),
      child: Row(
        children: [
          circle(size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textLine(width: double.infinity, height: 16),
                const SizedBox(height: AppSpacing.xs),
                textLine(width: 150, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
