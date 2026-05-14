import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthToggle extends StatefulWidget {
  const AuthToggle({super.key});

  @override
  State<AuthToggle> createState() => _AuthToggleState();
}

class _AuthToggleState extends State<AuthToggle> {
  bool showLogin = true;

  void toggleScreens() {
    setState(() {
      showLogin = !showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLogin) {
      return LoginScreen(showRegisterScreen: toggleScreens);
    } else {
      return RegisterScreen(showLoginScreen: toggleScreens);
    }
  }
}
