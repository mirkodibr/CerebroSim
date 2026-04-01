import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'app_shell.dart';

/// The entry point for existing users to authenticate with CerebroSim.
/// 
/// This screen provides an interface for logging in via email/password or Google
/// authentication. It utilizes [authProvider] to manage authentication state and
/// directs users to the [AppShell] upon successful login.
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
  /// It listens to [authProvider] to handle navigation on successful login
  /// or to show error messages if authentication fails.
  @override
  Widget build(BuildContext context) {
    /// Monitors the current authentication state to handle loading indicators.
    final authState = ref.watch(authProvider);
    final isLoading = authState is AsyncLoading;

    /// Listens for changes in the [authProvider] to handle navigation and errors.
    /// 
    /// If authentication is successful, it replaces the current screen with [AppShell].
    /// If an error occurs, it displays a [SnackBar] with the error message.
    ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AppShell()),
            );
          }
        },
        error: (e, s) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        },
        loading: () {},
      );
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text('Don\'t have an account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
