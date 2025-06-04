import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../config/theme/app_colors.dart';

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
  // Username controller removed
  final _fullNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    // Username controller dispose removed
    _fullNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuthForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    FocusScope.of(context).unfocus();

    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential;

      if (_isLoginMode) {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        print('Successfully logged in: ${userCredential.user?.uid}');
      } else {
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
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                // Username field removed from Firestore document
                'fullName': _fullNameController.text.trim(),
                'email': _emailController.text.trim(),
                'createdAt': Timestamp.now(),
                'uid': userCredential.user!.uid,
              });
          print(
            'Successfully signed up & data saved: ${userCredential.user?.uid}',
          );
        }
      }

      if (mounted) {
        _formKey.currentState?.reset();
        _emailController.clear();
        _passwordController.clear();
        // Username controller clear removed
        _fullNameController.clear();
        _confirmPasswordController.clear();
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
      print('Unexpected error: $err');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      // Username controller clear removed
      _fullNameController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

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
                Icon(Icons.vibration, size: 80, color: AppColors.secondary),
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

                // Full Name Field (only for Sign Up)
                if (!_isLoginMode)
                  TextFormField(
                    key: const ValueKey('fullName'),
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name.';
                      }
                      if (value.trim().length < 3) {
                        return 'Full name seems too short.';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                  ),
                if (!_isLoginMode) const SizedBox(height: 16),

                // Username Field and SizedBox REMOVED
                TextFormField(
                  key: const ValueKey('email'),
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        !value.trim().contains('@') ||
                        !value.trim().contains('.')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
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
                  validator: (value) {
                    if (value == null || value.trim().length < 7) {
                      return 'Password must be at least 7 characters long.';
                    }
                    return null;
                  },
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
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match!';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitAuthForm(),
                  ),
                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.error, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondary,
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _submitAuthForm,
                    child: Text(_isLoginMode ? 'LOG IN' : 'SIGN UP'),
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
