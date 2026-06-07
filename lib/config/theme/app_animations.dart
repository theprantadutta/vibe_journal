// lib/config/theme/app_animations.dart
import 'package:flutter/animation.dart';

class AppAnimations {
  // This class is not meant to be instantiated.
  AppAnimations._();

  // ============================================================
  // ANIMATION DURATIONS
  // ============================================================

  // Ultra fast (micro-interactions)
  static const Duration ultraFast = Duration(milliseconds: 100);

  // Fast (quick feedback)
  static const Duration fast = Duration(milliseconds: 200);

  // Normal (standard transitions)
  static const Duration normal = Duration(milliseconds: 300);

  // Medium (deliberate animations)
  static const Duration medium = Duration(milliseconds: 400);

  // Slow (emphasis animations)
  static const Duration slow = Duration(milliseconds: 500);

  // Very slow (special effects)
  static const Duration verySlow = Duration(milliseconds: 700);

  // Ultra slow (background effects)
  static const Duration ultraSlow = Duration(milliseconds: 1000);

  // ============================================================
  // SEMANTIC DURATIONS (Contextual names)
  // ============================================================

  // Button press
  static const Duration buttonPress = ultraFast; // 100ms

  // Page transitions
  static const Duration pageTransition = normal; // 300ms

  // Modal/Dialog
  static const Duration modalTransition = fast; // 200ms

  // Snackbar/Toast
  static const Duration snackbarTransition = fast; // 200ms

  // Card hover/press
  static const Duration cardPress = ultraFast; // 100ms

  // List item appearance
  static const Duration listItemAppear = fast; // 200ms

  // Shimmer animation cycle
  static const Duration shimmerCycle = Duration(milliseconds: 1500);

  // Stagger delay between items
  static const Duration staggerDelay = Duration(milliseconds: 50);

  // Chart animations
  static const Duration chartAnimation = slow; // 500ms

  // Orb pulsing animation
  static const Duration orbPulse = Duration(milliseconds: 1200);

  // Recording amplitude update
  static const Duration amplitudeUpdate = Duration(milliseconds: 150);

  // Success/Error animation
  static const Duration feedbackAnimation = medium; // 400ms

  // Theme transition
  static const Duration themeTransition = normal; // 300ms

  // ============================================================
  // ANIMATION CURVES
  // ============================================================

  // Standard easing
  static const Curve standard = Curves.easeInOut;

  // Emphasized easing (material design 3)
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  // Decelerate (easing out)
  static const Curve decelerate = Curves.easeOut;

  // Accelerate (easing in)
  static const Curve accelerate = Curves.easeIn;

  // Sharp (quick & snappy)
  static const Curve sharp = Curves.easeInExpo;

  // Smooth (gentle & fluid)
  static const Curve smooth = Curves.easeInOutQuad;

  // Bounce (playful)
  static const Curve bounce = Curves.bounceOut;

  // Elastic (springy)
  static const Curve elastic = Curves.elasticOut;

  // Spring (natural motion)
  static const Curve spring = Curves.easeOutBack;

  // ============================================================
  // SEMANTIC CURVES (Contextual names)
  // ============================================================

  // Button press
  static const Curve buttonCurve = smooth;

  // Page enter
  static const Curve pageEnter = emphasized;

  // Page exit
  static const Curve pageExit = accelerate;

  // Modal appear
  static const Curve modalAppear = spring;

  // Card press
  static const Curve cardCurve = smooth;

  // List item enter
  static const Curve listItemCurve = decelerate;

  // Scroll physics
  static const Curve scrollCurve = smooth;

  // Scale animations
  static const Curve scaleCurve = spring;

  // Fade animations
  static const Curve fadeCurve = standard;

  // Slide animations
  static const Curve slideCurve = emphasized;

  // ============================================================
  // SCALE VALUES
  // ============================================================

  // Pressed state scale
  static const double pressedScale = 0.95;

  // Hover state scale
  static const double hoverScale = 1.02;

  // Active state scale
  static const double activeScale = 1.05;

  // Pop-in scale (from)
  static const double popInScaleStart = 0.8;

  // Pop-in scale (to)
  static const double popInScaleEnd = 1.0;

  // Pulse scale (max)
  static const double pulseScaleMax = 1.1;

  // Orb active scale
  static const double orbActiveScale = 1.15;

  // ============================================================
  // OPACITY VALUES
  // ============================================================

  // Fully transparent
  static const double transparent = 0.0;

  // Subtle hint
  static const double hint = 0.3;

  // Disabled state
  static const double disabled = 0.5;

  // Semi-transparent
  static const double semiTransparent = 0.7;

  // Mostly opaque
  static const double mostlyOpaque = 0.9;

  // Fully opaque
  static const double opaque = 1.0;

  // ============================================================
  // STAGGER CONFIGURATION
  // ============================================================

  // Calculate stagger delay for index
  static Duration staggerDelayFor(int index, {Duration? baseDelay}) {
    return (baseDelay ?? staggerDelay) * index;
  }

  // ============================================================
  // ROTATION VALUES (in radians)
  // ============================================================

  static const double rotate45 = 0.785398; // π/4
  static const double rotate90 = 1.5708; // π/2
  static const double rotate180 = 3.14159; // π
  static const double rotate360 = 6.28319; // 2π

  // ============================================================
  // CUSTOM CURVES
  // ============================================================

  // Custom cubic bezier for subtle spring
  static const Curve subtleSpring = Cubic(0.34, 1.56, 0.64, 1);

  // Custom cubic bezier for smooth deceleration
  static const Curve smoothDecelerate = Cubic(0.0, 0.0, 0.2, 1);

  // Custom cubic bezier for material standard
  static const Curve materialStandard = Cubic(0.4, 0.0, 0.2, 1);

  // Custom cubic bezier for iOS-like motion
  static const Curve iosStandard = Cubic(0.4, 0.0, 0.6, 1);
}
