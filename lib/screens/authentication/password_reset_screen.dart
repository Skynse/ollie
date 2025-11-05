import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../components/ollie_ui/ollie_button.dart';
import '../../components/ollie_ui/ollie_textfield.dart';
import '../../components/ollie_ui/theme_extensions.dart';
import '../../repositories/appwrite/appwrite_config.dart';

/// Password reset screen - handles the second step after user clicks email link
/// URL format: /reset-password?userId=xxx&secret=xxx
class PasswordResetScreen extends ConsumerStatefulWidget {
  final String userId;
  final String secret;

  const PasswordResetScreen({
    super.key,
    required this.userId,
    required this.secret,
  });

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AppwriteConfig.completePasswordRecovery(
        userId: widget.userId,
        secret: widget.secret,
        newPassword: password,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });

      // Redirect to login after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/login');
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _parseError(e.toString());
      });
    }
  }

  String _parseError(String error) {
    if (error.contains('Invalid credentials')) {
      return 'Reset link is invalid or expired. Please request a new one.';
    }
    if (error.contains('Password')) {
      return 'Password does not meet requirements';
    }
    return 'Failed to reset password. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _isSuccess ? _buildSuccessView() : _buildResetForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline,
            color: Colors.green.shade600,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Password Reset!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: context.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your password has been successfully reset.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: context.textColor, height: 1.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Redirecting to login...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 48),

          // New password field
          OllieTextfield.password(
            controller: _passwordController,
            enabled: !_isLoading,
            helperText: 'Must be at least 8 characters',
            onSubmitted: (_) => _handlePasswordReset(),
          ),
          const SizedBox(height: 16),

          // Confirm password field
          OllieTextfield.password(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your new password',
            enabled: !_isLoading,
            onSubmitted: (_) => _handlePasswordReset(),
          ),
          const SizedBox(height: 24),

          // Error message
          if (_errorMessage != null) ...[
            _buildErrorMessage(_errorMessage!),
            const SizedBox(height: 16),
          ],

          // Submit button
          OllieButton(
            text: 'Reset Password',
            onPressed: _handlePasswordReset,
            loading: _isLoading,
            disabled: _isLoading,
          ),

          const SizedBox(height: 16),

          // Back to login
          OllieButton.text(
            text: 'Back to Login',
            onPressed: () => context.go('/login'),
          ),
        ],
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
                color: context.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.lock_reset, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: context.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your new password below',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: context.textColor, height: 1.5),
        ),
      ],
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
        ],
      ),
    );
  }
}
