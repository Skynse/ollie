import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:ollie/screens/authentication/register.dart';
import '../../config/environment.dart';

/// AuthGate checks if user is authenticated
/// If yes -> shows home screen
/// If no -> shows login screen
class AuthGate extends StatefulWidget {
  final Widget home;
  const AuthGate({super.key, required this.home});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Account _account;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  models.User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initAppwrite();
  }

  void _initAppwrite() async {
    try {
      final client = Client()
          .setEndpoint(Environment.appwritePublicEndpoint)
          .setProject(Environment.appwriteProjectId);

      _account = Account(client);

      // Check if user is already logged in
      await _checkAuth();
    } catch (e) {
      print('Error initializing Appwrite: $e');
      setState(() {
        _isLoading = false;
        _isAuthenticated = false;
      });
    }
  }

  Future<void> _checkAuth() async {
    try {
      final user = await _account.get();
      setState(() {
        _currentUser = user;
        _isAuthenticated = true;
        _isLoading = false;
      });
    } catch (e) {
      // User not authenticated
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  void _onAuthSuccess() {
    // Refresh auth state
    _checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isAuthenticated) {
      return widget.home;
    }

    return RegistrationPage(account: _account, onAuthSuccess: _onAuthSuccess);
  }
}
