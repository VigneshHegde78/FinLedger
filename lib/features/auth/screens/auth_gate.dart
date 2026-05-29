import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/routing/app_navigation.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to a continuous flow of data
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. While Firebase is connecting or checking the cache, show a loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. If the snapshot contains data, the user is safely logged in!
        if (snapshot.hasData) {
          return const AppNavigation(); // The bottom nav wrapper we built in Step 4
        }

        // 3. Otherwise, they are NOT logged in. Show the login screen.
        return const LoginScreen();
      },
    );
  }
}
