import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/core/services/biometric_auth_service.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;

  const LockScreen({super.key, required this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  // Animation controller for the pulsing lock icon
  late final AnimationController _iconPulseController;
  late final Animation<double> _iconScaleAnimation;

  // Animation controller for the moving background gradient
  late final AnimationController _gradientController;
  late final Animation<Alignment> _topAlignmentAnimation;
  late final Animation<Alignment> _bottomAlignmentAnimation;

  @override
  void initState() {
    super.initState();

    // Setup for the pulsing lock icon
    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _iconScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _iconPulseController, curve: Curves.easeInOut),
    );

    // Setup for the smoothly shifting background gradient
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _topAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.topRight,
          end: Alignment.bottomRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.bottomRight,
          end: Alignment.bottomLeft,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.bottomLeft,
          end: Alignment.topLeft,
        ),
        weight: 1,
      ),
    ]).animate(_gradientController);

    _bottomAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.bottomRight,
          end: Alignment.bottomLeft,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.bottomLeft,
          end: Alignment.topLeft,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.topRight,
          end: Alignment.bottomRight,
        ),
        weight: 1,
      ),
    ]).animate(_gradientController);
  }

  @override
  void dispose() {
    _iconPulseController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  Future<void> _authenticate(BuildContext context) async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate) Haptics.vibrate(HapticsType.medium);

    final didAuthenticate = await BiometricAuthService.authenticate(
      'Unlock VibeJournal to continue',
    );

    if (didAuthenticate) {
      widget.onUnlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gradientController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        const Color(0xFF1a0e2e).withOpacity(0.2),
                      ],
                      begin: _topAlignmentAnimation.value,
                      end: _bottomAlignmentAnimation.value,
                    ),
                  ),
                );
              },
            ),
          ),

          // Blurred Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _iconScaleAnimation,
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 64,
                    color: Colors.white.withOpacity(0.8),
                    shadows: [
                      Shadow(
                        blurRadius: 15,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "VibeJournal is Locked",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text(
                    "Unlock",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    backgroundColor: Colors.white.withOpacity(0.95),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    shadowColor: Colors.black.withOpacity(0.5),
                  ),
                  onPressed: () => _authenticate(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
