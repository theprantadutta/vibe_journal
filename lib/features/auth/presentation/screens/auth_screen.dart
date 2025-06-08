import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibe_journal/features/legal/presentation/privacy_policy_content.dart';
import 'package:vibe_journal/features/legal/presentation/terms_and_conditions_content.dart';
import '../../../../config/theme/app_colors.dart';
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
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final int _freeTierMaxCloudVibes = 75;
  final int _freeTierMaxRecordingDurationMinutes = 5;

  // State for legal agreement checkboxes
  bool _agreedToTerms = false;
  bool _agreedToPolicy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuthForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    FocusScope.of(context).unfocus();

    if (!isValid) return;

    // In signup mode, ensure terms and policy are agreed to
    if (!_isLoginMode && (!_agreedToTerms || !_agreedToPolicy)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must agree to the Terms & Conditions and Privacy Policy.',
          ),
          backgroundColor: AppColors.error,
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
            userModel = UserModel.fromFirestore(
              userDoc as DocumentSnapshot<Map<String, dynamic>>,
            );
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
            'maxCloudVibes': _freeTierMaxCloudVibes,
            'maxRecordingDurationMinutes': _freeTierMaxRecordingDurationMinutes,
          };
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(newUserFirestoreData);
          userModel = UserModel.fromFirestore(
            await _firestore
                    .collection('users')
                    .doc(userCredential.user!.uid)
                    .get()
                as DocumentSnapshot<Map<String, dynamic>>,
          );
        }
      }

      if (userModel != null) {
        registerUserSession(userModel);
      } else if (_isLoginMode && _errorMessage != null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    } on FirebaseAuthException catch (err) {
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
      _errorMessage = 'An unexpected error occurred. Please try again.';
      print('Unexpected error during auth: $err');
    }

    if (mounted)
      setState(() {
        _isLoading = false;
      });
  }

  void _toggleAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  void _showLegalDialog(Widget content) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
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
    final textTheme = theme.textTheme;
    final bool canSubmitSignup = _agreedToTerms && _agreedToPolicy;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Icon(
                  Icons.vibration,
                  size: 80,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 20),
                Text(
                  _isLoginMode ? 'Welcome Back!' : 'Create VibeJournal Account',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode
                      ? 'Log in to your VibeJournal'
                      : 'Sign up to start journaling your vibes',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
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
                  ),
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
                ),
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
                ),
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
                  ),

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
                                  style: const TextStyle(
                                    color: AppColors.primary,
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
                                  style: const TextStyle(
                                    color: AppColors.primary,
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
                  ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 10),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 16),

                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondary,
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _isLoginMode
                        ? _submitAuthForm
                        : (canSubmitSignup ? _submitAuthForm : null),
                    child: Text(_isLoginMode ? 'LOG IN' : 'CREATE ACCOUNT'),
                  ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: _toggleAuthMode,
                  child: Text(
                    _isLoginMode
                        ? 'Create new account'
                        : 'I already have an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
