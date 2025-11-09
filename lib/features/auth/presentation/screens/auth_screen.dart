// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vibe_journal/features/layout/main_app_layout.dart';
import 'package:vibe_journal/features/legal/presentation/privacy_policy_content.dart';
import 'package:vibe_journal/features/legal/presentation/terms_and_conditions_content.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_animations.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/widgets/animated_card.dart';
import '../../domain/models/user_model.dart';
import '../../../../core/services/service_locator.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State for legal agreement checkboxes
  bool _agreedToTerms = false;
  bool _agreedToPolicy = false;

  // Services
  final _hapticService = HapticService();
  final _soundService = SoundService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuthForm() async {
    _hapticService.light();

    final isValid = _formKey.currentState?.validate() ?? false;
    FocusScope.of(context).unfocus();

    if (!isValid) return;

    // In signup mode, ensure terms and policy are agreed to
    if (!_isLoginMode && (!_agreedToTerms || !_agreedToPolicy)) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      _hapticService.error();
      _soundService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'You must agree to the Terms & Conditions and Privacy Policy.',
          ),
          backgroundColor: AppColors.getError(isDark),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential;
      UserModel? userModel;

      if (_isLoginMode) {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (userCredential.user != null) {
          final userDoc = await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();
          if (userDoc.exists) {
            userModel = UserModel.fromFirestore(userDoc);
          } else {
            _errorMessage = 'User data not found. Please contact support.';
          }
        }
      } else {
        // Sign Up mode
        if (_passwordController.text.trim() !=
            _confirmPasswordController.text.trim()) {
          throw FirebaseAuthException(
            code: 'password-mismatch',
            message: 'Passwords do not match.',
          );
        }

        userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          final now = Timestamp.now();
          final Map<String, dynamic> newUserFirestoreData = {
            'fullName': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'createdAt': now,
            'uid': userCredential.user!.uid,
            'plan': 'free',
            'cloudVibeCount': 0,
            'notificationPreferences': {
              'dailyReminderEnabled': true,
              'streaksEnabled': true,
              'mindfulMomentsEnabled': true,
            },
          };
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(newUserFirestoreData);
          userModel = UserModel.fromFirestore(
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .get(),
          );
        }
      }

      if (userModel != null) {
        final userService = locator<UserService>();

        // Try to fetch user from backend API (preferred)
        final fetchedFromBackend = await userService.fetchAndUpdateUser();

        if (!fetchedFromBackend) {
          // Fallback to Firestore data if backend fetch failed
          if (kDebugMode) {
            print('⚠️ Using Firestore data as fallback');
          }
          await userService.updateUser(userModel);
        }

        _hapticService.success();
        _soundService.success();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainAppLayout()),
        );
      } else if (_isLoginMode && _errorMessage != null) {
        _hapticService.error();
        _soundService.error();
        setState(() {
          _isLoading = false;
        });
        return;
      }
    } on FirebaseAuthException catch (err) {
      _hapticService.error();
      _soundService.error();
      _errorMessage = err.message ?? 'An unknown error occurred.';
      if (err.code == 'weak-password') {
        _errorMessage = 'The password provided is too weak.';
      } else if (err.code == 'email-already-in-use') {
        _errorMessage = 'An account already exists for that email.';
      } else if (err.code == 'user-not-found' ||
          err.code == 'wrong-password' ||
          err.code == 'invalid-credential') {
        _errorMessage = 'Invalid email or password.';
      }
    } catch (err) {
      _hapticService.error();
      _soundService.error();
      _errorMessage = 'An unexpected error occurred. Please try again.';
      if (kDebugMode) {
        print('Unexpected error during auth: $err');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleAuthMode() {
    _hapticService.light();
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _handleGoogleSignIn() async {
    _hapticService.light();

    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = locator<AuthService>();
      final userCredential = await authService.signInWithGoogle();

      if (userCredential?.user != null) {
        final userService = locator<UserService>();

        // Try to fetch user from backend API (preferred)
        final fetchedFromBackend = await userService.fetchAndUpdateUser();

        if (!fetchedFromBackend) {
          // Fallback to Firestore data if backend fetch failed
          if (kDebugMode) {
            print('⚠️ Using Firestore data as fallback for Google Sign-In');
          }

          final userDoc = await _firestore
              .collection('users')
              .doc(userCredential!.user!.uid)
              .get();

          if (userDoc.exists) {
            final userModel = UserModel.fromFirestore(userDoc);
            await userService.updateUser(userModel);
          }
        }

        _hapticService.success();
        _soundService.success();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainAppLayout()),
        );
      } else {
        _errorMessage = 'Google Sign-In was cancelled or failed.';
      }
    } catch (err) {
      _hapticService.error();
      _soundService.error();
      _errorMessage = 'An error occurred during Google Sign-In. Please try again.';
      if (kDebugMode) {
        print('Error during Google Sign-In: $err');
      }
    }

    if (mounted) {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

  void _showLegalDialog(Widget content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.getSurface(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Expanded(child: content),
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;
    final bool canSubmitSignup = _agreedToTerms && _agreedToPolicy;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: AnimatedCard(
                margin: const EdgeInsets.all(AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: AppAnimations.normal,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      key: ValueKey(_isLoginMode),
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.secondaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.getSecondary(isDark).withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.vibration,
                            size: 50,
                            color: Colors.white,
                          ),
                        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(duration: 300.ms, delay: 50.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 20),
                        Text(
                          _isLoginMode ? 'Welcome Back!' : 'Create VibeJournal Account',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            color: AppColors.getTextPrimary(isDark),
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 8),
                        Text(
                          _isLoginMode
                              ? 'Log in to your VibeJournal'
                              : 'Sign up to start journaling your vibes',
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.getTextSecondary(isDark),
                          ),
                        ).animate().fadeIn(duration: 300.ms, delay: 150.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 32),

                        if (!_isLoginMode)
                          TextFormField(
                            key: const ValueKey('fullName'),
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().length < 3)
                                ? 'Full name seems too short.'
                                : null,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                          ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
                        if (!_isLoginMode) const SizedBox(height: 16),

                        TextFormField(
                          key: const ValueKey('email'),
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || !v.trim().contains('@'))
                              ? 'Please enter a valid email address.'
                              : null,
                          textInputAction: TextInputAction.next,
                        ).animate().fadeIn(duration: 300.ms, delay: 250.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 16),

                        TextFormField(
                          key: const ValueKey('password'),
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          obscureText: true,
                          validator: (v) => (v == null || v.trim().length < 7)
                              ? 'Password must be at least 7 characters long.'
                              : null,
                          textInputAction: _isLoginMode
                              ? TextInputAction.done
                              : TextInputAction.next,
                          onFieldSubmitted: _isLoginMode
                              ? (_) => _submitAuthForm()
                              : null,
                        ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 16),

                        if (!_isLoginMode)
                          TextFormField(
                            key: const ValueKey('confirm_password'),
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                            obscureText: true,
                            validator: (v) => (v != _passwordController.text)
                                ? 'Passwords do not match!'
                                : null,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submitAuthForm(),
                          ).animate().fadeIn(duration: 300.ms, delay: 350.ms).slideY(begin: 0.2, end: 0),

                        // --- NEW: Legal Agreement Section for Signup ---
                        if (!_isLoginMode)
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                            child: Column(
                              children: [
                                CheckboxListTile(
                                  value: _agreedToTerms,
                                  onChanged: (value) =>
                                      setState(() => _agreedToTerms = value ?? false),
                                  title: RichText(
                                    text: TextSpan(
                                      style: textTheme.bodySmall,
                                      children: [
                                        const TextSpan(
                                          text: 'I have read and agree to the ',
                                        ),
                                        TextSpan(
                                          text: 'Terms & Conditions',
                                          style: TextStyle(
                                            color: AppColors.getPrimary(isDark),
                                            decoration: TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => _showLegalDialog(
                                              const TermsAndConditionsContent(),
                                            ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                                CheckboxListTile(
                                  value: _agreedToPolicy,
                                  onChanged: (value) =>
                                      setState(() => _agreedToPolicy = value ?? false),
                                  title: RichText(
                                    text: TextSpan(
                                      style: textTheme.bodySmall,
                                      children: [
                                        const TextSpan(text: 'I acknowledge the '),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: TextStyle(
                                            color: AppColors.getPrimary(isDark),
                                            decoration: TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => _showLegalDialog(
                                              const PrivacyPolicyContent(),
                                            ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms, delay: 400.ms).slideY(begin: 0.2, end: 0),

                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 10),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: AppColors.getError(isDark),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ).animate().shake(duration: 400.ms),

                        const SizedBox(height: 16),

                        if (_isLoading)
                          Center(
                            child: CircularProgressIndicator(
                              color: AppColors.getSecondary(isDark),
                            ),
                          )
                        else
                          AnimatedButton(
                            onPressed: _isLoginMode
                                ? _submitAuthForm
                                : (canSubmitSignup ? _submitAuthForm : null),
                            enableHaptic: true,
                            child: Text(_isLoginMode ? 'LOG IN' : 'CREATE ACCOUNT'),
                          ).animate().fadeIn(duration: 300.ms, delay: 450.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 24),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.5),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.getTextSecondary(isDark),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.5),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 300.ms, delay: 470.ms),
                        const SizedBox(height: 24),

                        // Google Sign In Button
                        if (_isGoogleLoading)
                          Center(
                            child: CircularProgressIndicator(
                              color: AppColors.getSecondary(isDark),
                            ),
                          )
                        else
                          AnimatedButton(
                            onPressed: _handleGoogleSignIn,
                            enableHaptic: true,
                            gradient: LinearGradient(
                              colors: [
                                isDark ? Colors.grey.shade800 : Colors.white,
                                isDark ? Colors.grey.shade700 : Colors.grey.shade50,
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.google,
                                  color: Colors.red.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isLoginMode ? 'SIGN IN WITH GOOGLE' : 'SIGN UP WITH GOOGLE',
                                  style: TextStyle(
                                    color: AppColors.getTextPrimary(isDark),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms, delay: 490.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: _toggleAuthMode,
                          child: Text(
                            _isLoginMode
                                ? 'Create new account'
                                : 'I already have an account',
                          ),
                        ).animate().fadeIn(duration: 300.ms, delay: 510.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
