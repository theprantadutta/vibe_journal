// lib/core/widgets/celebration_particles.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../config/theme/app_colors.dart';

/// A widget that displays celebration particles/confetti
/// for achievements, milestones, and special moments
class CelebrationParticles extends StatefulWidget {
  final bool autoPlay;
  final Duration duration;
  final List<Color>? colors;
  final double blastDirectionality; // 0 = random, 1 = straight up
  final double emissionFrequency; // 0.0 to 1.0, higher = more particles
  final int numberOfParticles;
  final double gravity; // 0.0 to 1.0, higher = faster fall
  final bool loop;
  final Widget? child;

  const CelebrationParticles({
    super.key,
    this.autoPlay = true,
    this.duration = const Duration(seconds: 3),
    this.colors,
    this.blastDirectionality = 0.5,
    this.emissionFrequency = 0.05,
    this.numberOfParticles = 20,
    this.gravity = 0.3,
    this.loop = false,
    this.child,
  });

  @override
  State<CelebrationParticles> createState() => _CelebrationParticlesState();
}

class _CelebrationParticlesState extends State<CelebrationParticles> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: widget.duration);

    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.play();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Play the confetti animation
  void play() {
    if (mounted) {
      _controller.play();
    }
  }

  /// Stop the confetti animation
  void stop() {
    if (mounted) {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColors =
        widget.colors ??
        [
          AppColors.darkPrimary,
          AppColors.darkSecondary,
          AppColors.successDark,
          AppColors.infoDark,
          AppColors.warningDark,
        ];

    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: widget.emissionFrequency,
            numberOfParticles: widget.numberOfParticles,
            gravity: widget.gravity,
            shouldLoop: widget.loop,
            colors: effectiveColors,
            maxBlastForce: 20,
            minBlastForce: 5,
            blastDirection: -pi / 2, // Up
            particleDrag: 0.05,
          ),
        ),
      ],
    );
  }
}

/// Preset celebration widgets for common scenarios
class CelebrationPresets {
  /// Subtle celebration (for minor achievements)
  static Widget subtle({Widget? child}) {
    return CelebrationParticles(
      autoPlay: true,
      duration: const Duration(seconds: 2),
      numberOfParticles: 10,
      emissionFrequency: 0.1,
      gravity: 0.2,
      child: child,
    );
  }

  /// Standard celebration (for regular achievements)
  static Widget standard({Widget? child}) {
    return CelebrationParticles(
      autoPlay: true,
      duration: const Duration(seconds: 3),
      numberOfParticles: 20,
      emissionFrequency: 0.05,
      gravity: 0.3,
      child: child,
    );
  }

  /// Epic celebration (for major milestones)
  static Widget epic({Widget? child}) {
    return CelebrationParticles(
      autoPlay: true,
      duration: const Duration(seconds: 5),
      numberOfParticles: 40,
      emissionFrequency: 0.02,
      gravity: 0.25,
      child: child,
    );
  }

  /// Premium unlock celebration
  static Widget premiumUnlock({Widget? child}) {
    return CelebrationParticles(
      autoPlay: true,
      duration: const Duration(seconds: 4),
      numberOfParticles: 30,
      emissionFrequency: 0.03,
      gravity: 0.28,
      colors: [
        AppColors.darkPrimary,
        AppColors.darkSecondary,
        const Color(0xFFFFD700), // Gold
        const Color(0xFFFFA500), // Orange
      ],
      child: child,
    );
  }

  /// Streak milestone celebration
  static Widget streakMilestone({Widget? child}) {
    return CelebrationParticles(
      autoPlay: true,
      duration: const Duration(seconds: 3),
      numberOfParticles: 25,
      emissionFrequency: 0.04,
      gravity: 0.3,
      colors: [
        AppColors.successDark,
        AppColors.darkPrimary,
        AppColors.infoDark,
      ],
      child: child,
    );
  }
}

/// A helper widget to trigger confetti from anywhere in the widget tree
class CelebrationTrigger extends StatefulWidget {
  final Widget child;
  final GlobalKey<_CelebrationTriggerState> celebrationKey;

  const CelebrationTrigger({
    super.key,
    required this.child,
    required this.celebrationKey,
  });

  @override
  State<CelebrationTrigger> createState() => _CelebrationTriggerState();
}

class _CelebrationTriggerState extends State<CelebrationTrigger> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Trigger the celebration from anywhere
  void celebrate({CelebrationType type = CelebrationType.standard}) {
    if (mounted) {
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.3,
            shouldLoop: false,
            colors: [
              AppColors.darkPrimary,
              AppColors.darkSecondary,
              AppColors.successDark,
              AppColors.infoDark,
              AppColors.warningDark,
            ],
            maxBlastForce: 20,
            minBlastForce: 5,
            blastDirection: -pi / 2,
            particleDrag: 0.05,
          ),
        ),
      ],
    );
  }
}

/// Types of celebrations
enum CelebrationType { subtle, standard, epic, premium, streak }

/// Simple confetti burst overlay (can be shown with an Overlay)
class ConfettiBurst extends StatefulWidget {
  final VoidCallback? onComplete;

  const ConfettiBurst({super.key, this.onComplete});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 3));
    _controller.play();

    // Auto-complete after animation
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _controller,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.05,
          numberOfParticles: 30,
          gravity: 0.3,
          shouldLoop: false,
          colors: [
            AppColors.darkPrimary,
            AppColors.darkSecondary,
            AppColors.successDark,
            AppColors.infoDark,
            AppColors.warningDark,
          ],
          maxBlastForce: 25,
          minBlastForce: 10,
          blastDirection: -pi / 2,
          particleDrag: 0.05,
        ),
      ),
    );
  }
}

/// Helper function to show confetti as an overlay
void showConfetti(
  BuildContext context, {
  CelebrationType type = CelebrationType.standard,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => ConfettiBurst(
      onComplete: () {
        entry.remove();
      },
    ),
  );

  overlay.insert(entry);
}
