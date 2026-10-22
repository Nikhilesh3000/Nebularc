import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_scaffold.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    // Show splash while restoring session
    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF070A14),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note, color: Color(0xFF8A2BE2), size: 60),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Color(0xFF8A2BE2)),
            ],
          ),
        ),
      );
    }

    // Logged in → MainScaffold | Not logged in → LoginScreen
    return auth.isLoggedIn ? const MainScaffold() : const LoginScreen();
  }
}
