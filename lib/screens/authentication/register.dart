import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget {
  final Account account;
  final VoidCallback onAuthSuccess;

  const RegistrationPage({
    required this.account,
    required this.onAuthSuccess,
    super.key,
  });

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

class LoginPage extends StatefulWidget {
  final Account account;
  final VoidCallback onAuthSuccess;

  const LoginPage({
    required this.account,
    required this.onAuthSuccess,
    super.key,
  });

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
