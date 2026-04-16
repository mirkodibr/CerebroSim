import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

/// The entry point for existing users to authenticate with CerebroSim.
/// 
/// This screen provides an interface for logging in via email/password or Google
/// authentication. It utilizes [authProvider] to manage authentication state.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates a new [LoginScreen] instance.
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// The state for [LoginScreen], handling form validation and authentication interactions.
class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// Global key used to validate and manage the login form's state.
  final _formKey = GlobalKey<FormState>();
  
  /// Controller for the email input field.
  final _emailController = TextEditingController();
  
  /// Controller for the password input field.
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Builds the login UI, including form fields and authentication buttons.
  /// 
  /// It listens to [authProvider] for error messages if authentication fails.
  @override
  Widget build(BuildContext context) {
    /// Monitors the current authentication state to handle loading indicators.
    final authState = ref.watch(authProvider);
    final isLoading = authState is AsyncLoading;

    /// Listens for errors in the [authProvider] to show feedback.
    ref.listen<AsyncValue<dynamic>>(authProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          ref.read(authProvider.notifier).signIn(
                                _emailController.text,
                                _passwordController.text,
                              );
                        }
                      },
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Sign In'),
              ),
              OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () => ref.read(authProvider.notifier).signInWithGoogle(),
                child: const Text('Sign in with Google'),
              ),
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('Don\'t have an account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
