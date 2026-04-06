import 'package:flutter/material.dart';
import 'auth/auth_gate.dart';

class ShowcaseApp extends StatelessWidget {
  const ShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterFlow Showcase',
      theme: ThemeData(useMaterial3: true),
      home: const AuthGate(),
    );
  }
}