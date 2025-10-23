import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/components/ollie_ui/theme_extensions.dart';
import 'package:ollie/repositories/appwrite/appwrite_config.dart';
import '../../components/ollie_ui/ollie_button.dart';
import '../../components/ollie_ui/ollie_textfield.dart';
import '../../providers/auth_provider.dart';

/// Modern email-first authentication flow
/// Step 1: Enter email → Step 2: System determines login vs signup
class ModernAuthScreen extends ConsumerStatefulWidget {
  const ModernAuthScreen({super.key});

  @override
  ConsumerState<ModernAuthScreen> createState() => _ModernAuthScreenState();
}

class _ModernAuthScreenState extends ConsumerState<ModernAuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _emailSubmitted = false;
  bool _isExistingUser = false;
  bool _isCheckingEmail = false;
  String? _emailError;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !_isValidEmail(email)) {
      setState(() {
        _emailError = 'Please enter a valid email';
      });
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _emailError = null;
    });

    try {
      // check db to see if email exists somewhere in users directory
      bool exists = await checkUserByEmail(email);

      if (!mounted) return;

      if (exists) {
        setState(() {
          _isExistingUser = true;
        });
      }
      setState(() {
        _emailSubmitted = true;
        _isCheckingEmail = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isCheckingEmail = false;
        _emailError = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (password.isEmpty || password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    if (_isExistingUser) {
      // Login
      await ref.read(authProvider.notifier).login(email, password);
    } else {
      // Signup
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
        return;
      }
      await ref.read(authProvider.notifier).register(email, password, name);
    }
  }

  void _goBack() {
    _animationController.reverse().then((_) {
      setState(() {
        _emailSubmitted = false;
        _passwordController.clear();
        _nameController.clear();
      });
    });
  }

  Future<bool> checkUserByEmail(String email) async {
    Functions functions = Functions(AppwriteConfig.client);
    try {
      final response = await functions.createExecution(
        functionId: '68f65dce000d5613cd05',
        body: jsonEncode({'email': email}),
        method: ExecutionMethod.gET,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.responseStatusCode == 200) {
        final responseBody = jsonDecode(response.responseBody);
        // The server function you provided returns a JSON map: {'exists': true/false}
        return responseBody['exists'] as bool? ?? false;
      } else {
        print(
          'Error executing function [${response.status}]: ${response.responseBody}',
        );
        return false;
      }
    } on AppwriteException catch (e) {
      // The 'function_not_found' error you received will be caught here.
      // Please double-check the function ID in your Appwrite project console.
      print('Error checking user by email: $e');
      return false;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$',
    ).hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and title
                  _buildHeader(),
                  const SizedBox(height: 48),

                  // Auth form
                  if (!_emailSubmitted)
                    _buildEmailStep()
                  else
                    _buildPasswordStep(),

                  const SizedBox(height: 24),

                  // Error message from provider
                  if (authState.errorMessage != null)
                    _buildErrorMessage(authState.errorMessage!),

                  const SizedBox(height: 32),

                  // Social login (optional)
                  _buildSocialLogin(),

                  const SizedBox(height: 24),

                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.primaryColor,
                context.primaryColor.withValues(
                  green: 0.8,
                  blue: 0.9,
                  alpha: 1.0,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withValues(
                  green: 0.8,
                  blue: 0.9,
                  alpha: 0.3,
                ),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.dashboard_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Ollie',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: context.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _emailSubmitted
              ? (_isExistingUser ? 'Welcome back!' : 'Create your account')
              : 'Your team\'s kanban board',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: context.textColor, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OllieTextfield.email(
          controller: _emailController,
          errorText: _emailError,
          enabled: !_isCheckingEmail,
          autofocus: true,
          onSubmitted: (_) => _checkEmail(),
        ),
        const SizedBox(height: 16),
        OllieButton(
          text: 'Continue',
          onPressed: _checkEmail,
          loading: _isCheckingEmail,
          disabled: _isCheckingEmail,
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    final authState = ref.watch(authProvider);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Show email with edit button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _emailController.text,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    onPressed: _goBack,
                    tooltip: 'Change email',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Name field (only for new users)
            if (!_isExistingUser) ...[
              OllieTextfield(
                label: 'Name',
                hint: 'Enter your full name',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                enabled: !authState.isLoading,
              ),
              const SizedBox(height: 16),
            ],

            // Password field
            OllieTextfield.password(
              controller: _passwordController,
              enabled: !authState.isLoading,
              helperText: _isExistingUser
                  ? null
                  : 'Must be at least 8 characters',
              onSubmitted: (_) => _handleAuth(),
            ),
            const SizedBox(height: 16),

            // Toggle between login/signup
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isExistingUser
                      ? 'New to Ollie?'
                      : 'Already have an account?',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isExistingUser = !_isExistingUser;
                      _nameController.clear();
                    });
                  },
                  child: Text(_isExistingUser ? 'Create account' : 'Sign in'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Submit button
            OllieButton(
              text: _isExistingUser ? 'Sign In' : 'Create Account',
              onPressed: _handleAuth,
              loading: authState.isLoading,
              disabled: authState.isLoading,
            ),

            // Forgot password (only for login)
            if (_isExistingUser) ...[
              const SizedBox(height: 12),
              OllieButton.text(
                text: 'Forgot password?',
                onPressed: () async {
                  await ref
                      .read(authProvider.notifier)
                      .resetPassword(_emailController.text);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent!'),
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => ref.read(authProvider.notifier).clearError(),
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _socialButton(
                icon: Icons.g_mobiledata,
                label: 'Google',
                onPressed: () {
                  // TODO: Implement Google OAuth
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _socialButton(
                icon: Icons.apple,
                label: 'Apple',
                onPressed: () {
                  // TODO: Implement Apple OAuth
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: context.surfaceColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'Threadbearers internal tool',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.5),
    );
  }
}
