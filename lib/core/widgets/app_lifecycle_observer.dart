import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_journal/core/widgets/lock_screen.dart';

const String kBiometricLockEnabled = 'biometric_lock_enabled';

class AppLifecycleObserver extends StatefulWidget {
  final Widget child;
  const AppLifecycleObserver({super.key, required this.child});

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  // --- NEW: A flag to prevent the re-locking loop ---
  bool _isUnlocking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial lock check when the widget is first built
    _checkIfLocked();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkIfLocked() async {
    final preferences = await SharedPreferences.getInstance();
    final bool isBiometricEnabled =
        preferences.getBool(kBiometricLockEnabled) ?? false;
    if (isBiometricEnabled) {
      if (mounted) setState(() => _isLocked = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When the app is resumed from the background...
    if (state == AppLifecycleState.resumed) {
      // *** THE FIX: Only re-lock if we are not in the process of unlocking ***
      if (!_isUnlocking) {
        _checkIfLocked();
      }
    }
  }

  void _onUnlock() {
    setState(() {
      _isUnlocking = true; // Set the flag to true
      _isLocked = false;
    });

    // Reset the flag after a short delay to allow the app to settle.
    // This ensures the next time the app is truly resumed, it will lock correctly.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isUnlocking = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child, // This is your MainAppLayout
        // Conditionally show the LockScreen on top
        if (_isLocked) LockScreen(onUnlock: _onUnlock),
      ],
    );
  }
}
