import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/challenge_screen.dart';
import 'screens/sign_in_screen.dart';
import 'services/auth_service.dart';

class CloudQuestApp extends StatelessWidget {
  const CloudQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloud Quest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4B3CB8)),
      ),
      home: const AuthGate(),
    );
  }
}

/// Auth state alone decides which screen exists. There is no navigation to
/// the challenge, so after sign-out there is nothing to go "back" to.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _auth = AuthService();
  late final Stream<User?> _authState = _auth.authStateChanges;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return SignInScreen(auth: _auth);
        }
        // Keyed by uid: signing out or switching accounts throws away the old
        // screen's state, including progress and the coach's last reply.
        return ChallengeScreen(
          key: ValueKey(user.uid),
          user: user,
          auth: _auth,
        );
      },
    );
  }
}
