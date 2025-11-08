// lib/core/widgets/animated_button.dart
import 'package:flutter/material.dart';
import '../../config/theme/app_animations.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';

/// A button widget with built-in scale animation and haptic feedback
/// Provides a satisfying press effect and optional sound feedback
class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final bool enableHaptic;
  final bool enableSound;
  final double pressedScale;
  final Duration animationDuration;
  final Border? border;
  final Gradient? gradient;

  const AnimatedButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.padding,
    this.borderRadius,
    this.width,
    this.height,
    this.enableHaptic = true,
    this.enableSound = false,
    this.pressedScale = AppAnimations.pressedScale,
    this.animationDuration = AppAnimations.buttonPress,
    this.border,
    this.gradient,
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final _hapticService = HapticService();
  final _soundService = SoundService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.buttonCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
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
    if (widget.onPressed != null) {
      // Provide feedback
      if (widget.enableHaptic) {
        _hapticService.buttonTap();
      }
      if (widget.enableSound) {
        _soundService.buttonPress();
      }

      // Call the actual onPressed callback
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: widget.gradient == null
                ? (widget.backgroundColor ?? theme.colorScheme.primary)
                : null,
            gradient: widget.gradient,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            border: widget.border,
            boxShadow: widget.elevation != null && widget.elevation! > 0
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: widget.elevation!,
                      offset: Offset(0, widget.elevation! / 2),
                    ),
                  ]
                : null,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: widget.foregroundColor ?? theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// A text button variant with just scale animation (no background)
class AnimatedTextButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final bool enableHaptic;
  final bool enableSound;
  final double pressedScale;

  const AnimatedTextButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.foregroundColor,
    this.padding,
    this.enableHaptic = true,
    this.enableSound = false,
    this.pressedScale = AppAnimations.pressedScale,
  }) : super(key: key);

  @override
  State<AnimatedTextButton> createState() => _AnimatedTextButtonState();
}

class _AnimatedTextButtonState extends State<AnimatedTextButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final _hapticService = HapticService();
  final _soundService = SoundService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.buttonPress,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.buttonCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
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
    if (widget.onPressed != null) {
      if (widget.enableHaptic) {
        _hapticService.buttonTap();
      }
      if (widget.enableSound) {
        _soundService.buttonPress();
      }
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DefaultTextStyle(
            style: TextStyle(
              color: widget.foregroundColor ?? theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// An icon button variant with scale animation
class AnimatedIconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final Color? color;
  final double? size;
  final bool enableHaptic;
  final bool enableSound;
  final double pressedScale;
  final EdgeInsetsGeometry? padding;

  const AnimatedIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.size,
    this.enableHaptic = true,
    this.enableSound = false,
    this.pressedScale = AppAnimations.pressedScale,
    this.padding,
  }) : super(key: key);

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final _hapticService = HapticService();
  final _soundService = SoundService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.buttonPress,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.buttonCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
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
    if (widget.onPressed != null) {
      if (widget.enableHaptic) {
        _hapticService.buttonTap();
      }
      if (widget.enableSound) {
        _soundService.buttonPress();
      }
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: widget.padding ?? const EdgeInsets.all(8.0),
          child: IconTheme(
            data: IconThemeData(
              color: widget.color,
              size: widget.size ?? 24,
            ),
            child: widget.icon,
          ),
        ),
      ),
    );
  }
}
