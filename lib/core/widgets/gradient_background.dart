// lib/core/widgets/gradient_background.dart
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

/// A widget that displays an animated gradient background
class GradientBackground extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final bool animate;

  const GradientBackground({
    Key? key,
    required this.child,
    this.gradient,
    this.animate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveGradient = gradient ??
        (isDark
            ? AppColors.darkBackgroundGradient
            : AppColors.lightBackgroundGradient);

    if (animate) {
      return AnimatedGradientBackground(
        gradient: effectiveGradient,
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: effectiveGradient),
      child: child,
    );
  }
}

/// An animated gradient background that shifts colors over time
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final Gradient gradient;
  final Duration duration;

  const AnimatedGradientBackground({
    Key? key,
    required this.child,
    required this.gradient,
    this.duration = const Duration(seconds: 20),
  }) : super(key: key);

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: _createAnimatedGradient(),
          ),
          child: widget.child,
        );
      },
    );
  }

  Gradient _createAnimatedGradient() {
    if (widget.gradient is LinearGradient) {
      final linear = widget.gradient as LinearGradient;
      return LinearGradient(
        colors: linear.colors,
        stops: linear.stops,
        begin: Alignment.lerp(
          linear.begin as Alignment,
          Alignment.bottomRight,
          _controller.value,
        )!,
        end: Alignment.lerp(
          linear.end as Alignment,
          Alignment.topLeft,
          _controller.value,
        )!,
      );
    }

    return widget.gradient;
  }
}

/// Preset gradient backgrounds
class GradientBackgrounds {
  /// Primary brand gradient
  static Widget primary({required Widget child}) {
    return GradientBackground(
      gradient: AppColors.primaryGradient,
      child: child,
    );
  }

  /// Secondary brand gradient
  static Widget secondary({required Widget child}) {
    return GradientBackground(
      gradient: AppColors.secondaryGradient,
      child: child,
    );
  }

  /// Vibey gradient (purple to pink)
  static Widget vibey({required Widget child, bool animate = false}) {
    return GradientBackground(
      gradient: AppColors.vibeyGradient,
      animate: animate,
      child: child,
    );
  }

  /// Subtle background gradient based on theme
  static Widget subtle({required Widget child, required bool isDark}) {
    return GradientBackground(
      gradient:
          isDark ? AppColors.darkBackgroundGradient : AppColors.lightBackgroundGradient,
      child: child,
    );
  }
}
