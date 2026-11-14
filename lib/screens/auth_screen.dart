// lib/screens/auth_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return '\u0391\u03c5\u03c4\u03cc \u03c4\u03bf email \u03c7\u03c1\u03b7\u03c3\u03b9\u03bc\u03bf\u03c0\u03bf\u03b9\u03b5\u03af\u03c4\u03b1\u03b9 \u03ae\u03b4\u03b7. \u0394\u03bf\u03ba\u03b9\u03bc\u03ac\u03c3\u03c4\u03b5 \u03a3\u03cd\u03bd\u03b4\u03b5\u03c3\u03b7.';
      case 'invalid-email':
        return '\u039c\u03b7 \u03ad\u03b3\u03ba\u03c5\u03c1\u03b7 \u03b4\u03b9\u03b5\u03cd\u03b8\u03c5\u03bd\u03c3\u03b7 email.';
      case 'weak-password':
        return '\u039f \u03ba\u03c9\u03b4\u03b9\u03ba\u03cc\u03c2 \u03c0\u03c1\u03ad\u03c0\u03b5\u03b9 \u03bd\u03b1 \u03ad\u03c7\u03b5\u03b9 \u03c4\u03bf\u03c5\u03bb\u03ac\u03c7\u03b9\u03c3\u03c4\u03bf\u03bd 6 \u03c7\u03b1\u03c1\u03b1\u03ba\u03c4\u03ae\u03c1\u03b5\u03c2.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return '\u039b\u03ac\u03b8\u03bf\u03c2 email \u03ae \u03ba\u03c9\u03b4\u03b9\u03ba\u03cc\u03c2 \u03c0\u03c1\u03cc\u03c3\u03b2\u03b1\u03c3\u03b7\u03c2.';
      default:
        return e.message ?? '\u03a0\u03c1\u03bf\u03ad\u03ba\u03c5\u03c8\u03b5 \u03c3\u03c6\u03ac\u03bb\u03bc\u03b1 \u03b1\u03c5\u03b8\u03b5\u03bd\u03c4\u03b9\u03ba\u03bf\u03c0\u03bf\u03af\u03b7\u03c3\u03b7\u03c2.';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);

    try {
      if (_isRegisterMode) {
        await authService.upgradeGuestToEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await authService.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isRegisterMode
                ? '\u039f \u03bb\u03bf\u03b3\u03b1\u03c1\u03b9\u03b1\u03c3\u03bc\u03cc\u03c2 \u03b4\u03b7\u03bc\u03b9\u03bf\u03c5\u03c1\u03b3\u03ae\u03b8\u03b7\u03ba\u03b5 \u03ba\u03b1\u03b9 \u03c4\u03b1 \u03c6\u03c5\u03c4\u03ac \u03c3\u03b1\u03c2 \u03c3\u03c5\u03b3\u03c7\u03c1\u03bf\u03bd\u03af\u03c3\u03c4\u03b7\u03ba\u03b1\u03bd!'
                : '\u0395\u03c0\u03b9\u03c4\u03c5\u03c7\u03ae\u03c2 \u03c3\u03cd\u03bd\u03b4\u03b5\u03c3\u03b7!',
          ),
        ),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mapAuthError(e)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isPermanentUser = user != null && !user.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '\u039b\u03bf\u03b3\u03b1\u03c1\u03b9\u03b1\u03c3\u03bc\u03cc\u03c2 & \u03a3\u03c5\u03b3\u03c7\u03c1\u03bf\u03bd\u03b9\u03c3\u03bc\u03cc\u03c2',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: isPermanentUser
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                child: Icon(
                  Icons.verified_user,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '\u03a3\u03c5\u03bd\u03b4\u03b5\u03b4\u03b5\u03bc\u03ad\u03bd\u03bf\u03c2 \u039b\u03bf\u03b3\u03b1\u03c1\u03b9\u03b1\u03c3\u03bc\u03cc\u03c2',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user.email ?? '',
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.logout),
                label: const Text('\u0391\u03c0\u03bf\u03c3\u03cd\u03bd\u03b4\u03b5\u03c3\u03b7'),
              ),
            ],
          )
              : Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.cloud_sync_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  _isRegisterMode
                      ? '\u0394\u03b7\u03bc\u03b9\u03bf\u03c5\u03c1\u03b3\u03af\u03b1 \u039b\u03bf\u03b3\u03b1\u03c1\u03b9\u03b1\u03c3\u03bc\u03bf\u03cd'
                      : '\u03a3\u03cd\u03bd\u03b4\u03b5\u03c3\u03b7 \u03c3\u03c4\u03bf\u03bd \u039b\u03bf\u03b3\u03b1\u03c1\u03b9\u03b1\u03c3\u03bc\u03cc \u03c3\u03b1\u03c2',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRegisterMode
                      ? '\u0391\u03c0\u03bf\u03b8\u03b7\u03ba\u03b5\u03cd\u03c3\u03c4\u03b5 \u03c4\u03b1 \u03c6\u03c5\u03c4\u03ac \u03ba\u03b1\u03b9 \u03c4\u03bf \u03b9\u03c3\u03c4\u03bf\u03c1\u03b9\u03ba\u03cc \u03c0\u03bf\u03c4\u03af\u03c3\u03bc\u03b1\u03c4\u03bf\u03c2 \u03c3\u03c4\u03bf cloud \u03ce\u03c3\u03c4\u03b5 \u03bd\u03b1 \u03ad\u03c7\u03b5\u03c4\u03b5 \u03c0\u03c1\u03cc\u03c3\u03b2\u03b1\u03c3\u03b7 \u03b1\u03c0\u03cc \u03ba\u03ac\u03b8\u03b5 \u03c3\u03c5\u03c3\u03ba\u03b5\u03c5\u03ae.'
                      : '\u03a3\u03c5\u03bd\u03b4\u03b5\u03b8\u03b5\u03af\u03c4\u03b5 \u03b3\u03b9\u03b1 \u03bd\u03b1 \u03b1\u03bd\u03b1\u03ba\u03c4\u03ae\u03c3\u03b5\u03c4\u03b5 \u03c4\u03b1 \u03b1\u03c0\u03bf\u03b8\u03b7\u03ba\u03b5\u03c5\u03bc\u03ad\u03bd\u03b1 \u03c6\u03c5\u03c4\u03ac \u03c3\u03b1\u03c2.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || !v.contains('@')) {
                      return '\u0395\u03b9\u03c3\u03ac\u03b3\u03b5\u03c4\u03b5 \u03ad\u03b3\u03ba\u03c5\u03c1\u03bf email.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: '\u039a\u03c9\u03b4\u03b9\u03ba\u03cc\u03c2 \u03c0\u03c1\u03cc\u03c3\u03b2\u03b1\u03c3\u03b7\u03c2',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return '\u03a4\u03bf\u03c5\u03bb\u03ac\u03c7\u03b9\u03c3\u03c4\u03bf\u03bd 6 \u03c7\u03b1\u03c1\u03b1\u03ba\u03c4\u03ae\u03c1\u03b5\u03c2.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    _isRegisterMode
                        ? '\u0395\u03b3\u03b3\u03c1\u03b1\u03c6\u03ae & \u03a3\u03c5\u03b3\u03c7\u03c1\u03bf\u03bd\u03b9\u03c3\u03bc\u03cc\u03c2'
                        : '\u03a3\u03cd\u03bd\u03b4\u03b5\u03c3\u03b7',
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegisterMode = !_isRegisterMode;
                    });
                  },
                  child: Text(
                    _isRegisterMode
                        ? '\u0388\u03c7\u03b5\u03c4\u03b5 \u03ae\u03b4\u03b7 \u03bb\u03bf\u03b3\u03b1\u03c1\u03b9\u03b1\u03c3\u03bc\u03cc; \u03a3\u03cd\u03bd\u03b4\u03b5\u03c3\u03b7'
                        : '\u039d\u03ad\u03bf\u03c2 \u03c7\u03c1\u03ae\u03c3\u03c4\u03b7\u03c2; \u0394\u03b7\u03bc\u03b9\u03bf\u03c5\u03c1\u03b3\u03af\u03b1 \u03bb\u03bf\u03b3\u03b1\u03c1\u03b9\u03b1\u03c3\u03bc\u03bf\u03cd',
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