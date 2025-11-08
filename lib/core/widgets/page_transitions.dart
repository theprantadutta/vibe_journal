// lib/core/widgets/page_transitions.dart
import 'package:flutter/material.dart';
import '../../config/theme/app_animations.dart';

/// Custom page route with slide and fade transition
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final AxisDirection direction;

  SlidePageRoute({
    required this.page,
    this.direction = AxisDirection.left,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppAnimations.pageTransition,
          reverseTransitionDuration: AppAnimations.pageTransition,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: _getBeginOffset(direction),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppAnimations.pageEnter,
            ));

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppAnimations.fadeCurve,
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );

  static Offset _getBeginOffset(AxisDirection direction) {
    switch (direction) {
      case AxisDirection.up:
        return const Offset(0.0, 1.0);
      case AxisDirection.down:
        return const Offset(0.0, -1.0);
      case AxisDirection.left:
        return const Offset(1.0, 0.0);
      case AxisDirection.right:
        return const Offset(-1.0, 0.0);
    }
  }
}

/// Fade page route transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppAnimations.pageTransition,
          reverseTransitionDuration: AppAnimations.pageTransition,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: AppAnimations.fadeCurve,
              )),
              child: child,
            );
          },
        );
}

/// Scale and fade page route transition
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScalePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppAnimations.pageTransition,
          reverseTransitionDuration: AppAnimations.pageTransition,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleAnimation = Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppAnimations.scaleCurve,
            ));

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppAnimations.fadeCurve,
            ));

            return ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Shared axis transition (Material Design)
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SharedAxisTransitionType transitionType;

  SharedAxisPageRoute({
    required this.page,
    this.transitionType = SharedAxisTransitionType.scaled,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppAnimations.pageTransition,
          reverseTransitionDuration: AppAnimations.pageTransition,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (transitionType) {
              case SharedAxisTransitionType.horizontal:
                return _buildHorizontalTransition(
                  animation,
                  secondaryAnimation,
                  child,
                );
              case SharedAxisTransitionType.vertical:
                return _buildVerticalTransition(
                  animation,
                  secondaryAnimation,
                  child,
                );
              case SharedAxisTransitionType.scaled:
                return _buildScaledTransition(
                  animation,
                  secondaryAnimation,
                  child,
                );
            }
          },
        );

  static Widget _buildHorizontalTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: AppAnimations.emphasized,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static Widget _buildVerticalTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: AppAnimations.emphasized,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static Widget _buildScaledTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: AppAnimations.emphasized,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

enum SharedAxisTransitionType {
  horizontal,
  vertical,
  scaled,
}

/// Helper extension to easily navigate with custom transitions
extension NavigatorTransitions on BuildContext {
  Future<T?> pushWithSlide<T>(Widget page, {AxisDirection direction = AxisDirection.left}) {
    return Navigator.of(this).push<T>(
      SlidePageRoute(page: page, direction: direction),
    );
  }

  Future<T?> pushWithFade<T>(Widget page) {
    return Navigator.of(this).push<T>(
      FadePageRoute(page: page),
    );
  }

  Future<T?> pushWithScale<T>(Widget page) {
    return Navigator.of(this).push<T>(
      ScalePageRoute(page: page),
    );
  }
}
