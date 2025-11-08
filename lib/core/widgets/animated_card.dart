// lib/core/widgets/animated_card.dart
import 'package:flutter/material.dart';
import '../../config/theme/app_animations.dart';
import '../../config/theme/app_spacing.dart';
import '../services/haptic_service.dart';

/// A card widget with press animation and optional tap handling
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Border? border;
  final bool enableHaptic;
  final double pressedScale;
  final Gradient? gradient;

  const AnimatedCard({
    Key? key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.color,
    this.elevation,
    this.margin,
    this.padding,
    this.borderRadius,
    this.border,
    this.enableHaptic = true,
    this.pressedScale = AppAnimations.pressedScale,
    this.gradient,
  }) : super(key: key);

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final _hapticService = HapticService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.cardPress,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.cardCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onTap() {
    if (widget.onTap != null) {
      if (widget.enableHaptic) {
        _hapticService.light();
      }
      widget.onTap!();
    }
  }

  void _onLongPress() {
    if (widget.onLongPress != null) {
      if (widget.enableHaptic) {
        _hapticService.longPress();
      }
      widget.onLongPress!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget card = Container(
      margin: widget.margin,
      padding: widget.padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: widget.gradient == null
            ? (widget.color ?? theme.cardTheme.color)
            : null,
        gradient: widget.gradient,
        borderRadius:
            widget.borderRadius ?? BorderRadius.circular(AppSpacing.cardRadius),
        border: widget.border,
        boxShadow: widget.elevation != null
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: widget.elevation!,
                  offset: Offset(0, widget.elevation! / 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: AppSpacing.elevationSm,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: widget.child,
    );

    if (widget.onTap != null || widget.onLongPress != null) {
      return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _onTap,
        onLongPress: _onLongPress,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: card,
        ),
      );
    }

    return card;
  }
}
